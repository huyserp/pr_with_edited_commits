# We believe that commits in a proper pull request stand on their own. There should be no “editing
# history”, meaning that each changed row in each file should only be affected by a single commit
# only.
# Provide a github link of your solution for the following:
# Crawl the rails/rails github repo and list all the pull requests where there are rows in files
# affected by multiple commits. Please provide links to the specific rows as well.

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
  commit_hash['commit_url'] = commit['href']
  commit_hash['files'] = []
  sleep 2
  commit_doc = Nokogiri::HTML(URI.open("https://github.com#{commit['href']}").read)
  # This must be #search twice as each filename link is under a different, unique div#id get the parent, then the nested child
  files = commit_doc.search('div.js-diff-progressive-container > div').search('div > div > a')

  files.each do |file|
    file_hash = {}
    file_hash["Filename"] = file.text.strip
    file_hash["file_url"] = file['href']
    file_hash["changed_lines"] = []
    sleep 2
    changed_lines_doc = Nokogiri::HTML(URI.open("https://github.com#{commit['href']}#{file['href']}").read)
    data_diff_anchor = file['href']
    data_diff_anchor.slice!(0)
    line_deletion = changed_lines_doc.search("table[data-diff-anchor='#{data_diff_anchor}'] td.blob-num.blob-num-deletion.js-linkable-line-number")
    unless line_deletion.empty?
      line_deletion = line_deletion.map { |line| line['data-line-number'].to_i }
      file_hash['changed_lines'] << line_deletion
    end
    line_addition = changed_lines_doc.search("table[data-diff-anchor='#{data_diff_anchor}'] td.blob-num.blob-num-addition.js-linkable-line-number")
    unless line_addition.empty?
      line_addition = line_addition.map { |line| line['data-line-number'].to_i }
      file_hash['changed_lines'] << line_addition
    end
    commit_hash['files'] << file_hash
  end
  pr_hash["commits"] << commit_hash
end
binding.pry


puts pr_hash






