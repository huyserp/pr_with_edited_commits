require 'pry'
require 'open-uri'
require 'nokogiri'
require_relative 'pr_links'

def find_pull_requests(url_list)
  results = []
  url_list.each do |pr_url|
    puts pr_url
    pr_doc = Nokogiri::HTML(URI.open("https://github.com#{pr_url}").read)
    number_of_commits = pr_doc.search('#commits_tab_counter').text.strip.to_i

    # If there is only one commit in this PR, move on to next pr_url
    next if number_of_commits < 2

    pr_hash = {}
    pr_hash["PR_title"] = pr_doc.search('span.js-issue-title.markdown-title').text.strip
    pr_hash["commits"] = []
    sleep 2
    pr_commits_doc = Nokogiri::HTML(URI.open("https://github.com#{pr_url}/commits").read)
    commits = pr_commits_doc.search('div#commits_bucket > div > div > div > div:nth-child(2) > ol > li > div > p > a:nth-child(1)')
    commits.each do |commit|
      commit_hash = {}
      commit_hash["commit_title"] = commit.text.strip
      commit_hash['commit_url'] = "https://github.com#{commit['href']}"
      commit_hash['files'] = []
      sleep 2
      commit_doc = Nokogiri::HTML(URI.open(commit_hash['commit_url']).read)
      # This must be #search twice as each filename link is under a different, unique div#id get the parent, then the nested child
      files = commit_doc.search('div.js-diff-progressive-container > div').search('div > div > a')

      files.each do |file|
        file_hash = {}
        file_hash["filename"] = file.text.strip
        file_hash["file_url"] = "#{commit_hash['commit_url']}#{file['href']}"
        file_hash["changed_lines"] = []
        sleep 2
        changed_lines_doc = Nokogiri::HTML(URI.open(file_hash["file_url"]).read)
        data_diff_anchor = file['href']
        data_diff_anchor.slice!(0)
        line_deletion = changed_lines_doc.search("table[data-diff-anchor='#{data_diff_anchor}'] td.blob-num.blob-num-deletion.js-linkable-line-number")
        unless line_deletion.empty?
          line_deletion = line_deletion.map { |line| "-#{line['data-line-number']}".to_i }
          file_hash['changed_lines'] << line_deletion
        end
        line_addition = changed_lines_doc.search("table[data-diff-anchor='#{data_diff_anchor}'] td.blob-num.blob-num-addition.js-linkable-line-number")
        unless line_addition.empty?
          line_addition = line_addition.map { |line| line['data-line-number'].to_i }
          file_hash['changed_lines'] << line_addition
        end
        # file_hash['changed_lines'] is currently an array of two nested arrays. This is how it was parsed, but they don't need
        # to be nested arrays going further.
        file_hash['changed_lines'].flatten!
        commit_hash['files'] << file_hash
      end
      pr_hash["commits"] << commit_hash
    end

    ### START THE COMPARISON
    files_in_all_commits = []
    pr_hash['commits'].each { |commit| files_in_all_commits << commit['files'].map { |file| file['filename'] } }

    # If the files changed in each commit are unique to that commit then to move on
    next if files_in_all_commits.flatten.count == files_in_all_commits.flatten.uniq.count

    # reduce the list of files to only those that are duplicated
    files_affected_by_more_than_one_commit = files_in_all_commits.flatten.group_by { |file| file }.select { |key, value| value.size > 1 }.map(&:first)

    # get the file hashes from each commit that are a match
    all_file_hash_matches = []
    files_affected_by_more_than_one_commit.each do |file|
      pr_hash['commits'].each do |commit|
        file_hash = commit['files'].select { |hash| hash['filename'] == file }
        all_file_hash_matches << file_hash
      end
    end

    # the above produces empty [] elements, this removes them so the final block can work.
    all_file_hash_matches.flatten!

    # finally, below we comepare matching filenames from different commits to see if they share changed lines of code.
    # negative numbers represent deletions of code, positive additions. though the abs value is retrieved for the url,
    # it determines 'L#{num}' (for deletion) or 'R#{num}' for addition in the url - this assures the correct link is produced.
    links_to_shared_lines = []
    all_file_hash_matches.each_with_index do |hash, index|
      next_hash = all_file_hash_matches[index + 1]
      if next_hash
        if hash['filename'] == next_hash['filename']
          nums = hash['changed_lines'] & next_hash['changed_lines']
          nums.each do |num|
            num.positive? ? links_to_shared_lines << "#{hash['file_url']}R#{num}" : links_to_shared_lines << "#{hash['file_url']}L#{num.abs}"
          end
        end
      end
    end

    links_to_shared_lines.unshift(pr_hash["PR_title"])
    results << links_to_shared_lines
  end
  results
end

pull_request_links_in_rails_repo = get_pr_links
find_pull_requests(pull_request_links_in_rails_repo)

