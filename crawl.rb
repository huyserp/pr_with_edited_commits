# We believe that commits in a proper pull request stand on their own. There should be no “editing
# history”, meaning that each changed row in each file should only be affected by a single commit
# only.
# Provide a github link of your solution for the following:
# Crawl the rails/rails github repo and list all the pull requests where there are rows in files
# affected by multiple commits. Please provide links to the specific rows as well.


  ### While I am familiar with rspec, can read and understand already written tests,
  ### and can run rake to execute rspec tests and understand the terminal output,
  ### I am unable to write rspec tests at this time (have not learned yet).
  ### For this reason I cannot test the below code.

  ### I also cannot run it as it would take {input hours} hours with more thank 27,000 PRs to check in the rails repo.

  ### I know there are exceptions that are not addressed in the below code. Among others, I just discovered that its
  ### possible for a PR with 2 commits to only lists one changed file. This disrupts my approach and now requires
  ### heavy refactoring.

  ### At the very least I've tried to express my thought process in approaching this task and you can hopefully see the
  ### direction I was going.

require 'pry'
require 'open-uri'
require 'nokogiri'
require_relative 'pr_links'

pr_url = '/rails/rails/pull/43240'
pr_doc = Nokogiri::HTML(URI.open("https://github.com#{pr_url}").read)
number_of_commits = pr_doc.search('#commits_tab_counter').text.strip.to_i

# If there is only one commit in this PR, move on to next pr_url
# next if number_of_commits < 2

pr_hash = {}
pr_hash["PR_title"] = pr_doc.search('span.js-issue-title.markdown-title').text.strip
pr_hash["commits"] = []
sleep 2
pr_commits_doc = Nokogiri::HTML(URI.open("https://github.com#{pr_url}/commits").read)
commits = pr_commits_doc.search('div#commits_bucket > div > div > div > div:nth-child(2) > ol > li > div > p > a')
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
    # affected lines of code can be deletions or additions, but for the purpose of comparing files in commits of PRs, we done care
    # if it was an addition or deletion - It's only necessary to gather both.
    file_hash['changed_lines'].flatten!.uniq!
    commit_hash['files'] << file_hash
  end
  pr_hash["commits"] << commit_hash
end

### START THE COMPARISON

files_in_all_commits = []
pr_hash['commits'].each { |commit| files_in_all_commits << commit['files'].map { |file| file['filename'] } }

# If the files changed in each commit are unique to that commit then to move on
# next if files_in_all_commits.flatten.count == files_in_all_commits.flatten.uniq.count

# reduce the list of files to only those (or the one) that are duplicated / has a duplicate (if they exist at all)
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
      binding.pry
    end
  end
end

links_to_shared_lines.unshift(pr_hash["PR_title"])
links_to_shared_lines
