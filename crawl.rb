  ### This script is not finished.  While I am familiar with rspec, can read and understand already written tests,
  ### and can run rake to execute rspec tests and understand the terminal output, I am unable to write rspec tests
  ### at this time (have not learned yet). For this reason I cannot test the below code.
  ### I also cannot run it as it would take at least 16 hours with more thank 27,000 PRs to check in the rails repo.

  ### I know there are exceptions that are not addressed in the below code. Among others, I just discovered that its
  ### possible for a PR with 2 commits to only lists one changed file. This disrupts my approach and now requires
  ### heavy refactoring.

  ### At the very least I've tried to express my thought process in approaching this task and you can hopefully see the
  ### direction I was going.

require 'pry'
require 'open-uri'
require 'nokogiri'

# the first PR has an id of 4
rails_pr_id = 4
rails_pr_url = "https://github.com/rails/rails/pull/#{rails_pr_id}/files"

rails_gh_pr_index_decs_url = "https://github.com/rails/rails/pulls?q=is%3Apr+sort%3Acreated-desc"
pr_index_page_document = Nokogiri::HTML(URI.open(rails_gh_pr_index_decs_url).read)
last_rails_pr_id = pr_index_page_document.search('span.opened-by').first.text.strip.slice(1..5)

resulting_pull_requests_with_link = {}
loop do
  break if rails_pr_id > last_rails_pr_id # There are no more Pull Requests

  begin
    html_file = URI.open(rails_gh_url).read
  rescue OpenURI::HTTPError
    sleep 2
    next #this pr_id doesnt exist resulting in 404 - go to next pr_id
  elsif rails_pr_url.includes('/issues/')
    sleep 2
    next #some urls with /pull/#{rails_pr_id} redirect to "issues", we don't want this
  else
    html_doc = Nokogiri::HTML(html_file)
  end

  changed_files_list = []

  # the 6th element (becoming the 1st) is the name of the PR - all elements following are files changed in this PR
  html_doc.search('a.Link--primary')[6..].each do |element|
    changed_files_list << element.text.strip
  end

  #reduce the list of files to only those (or the one) that are duplicated / has a duplicate (if they exist at all)
  duplicated_files = changed_files_list.group_by { |file| file }.select { |key, value| value.size > 1 }.map(&:first)

  # if the length of each list of files is the same, then the same file wasn't manipulated twice within the PR, move on.
  next if duplicated_files.empty?

  # The following PRs have at least one file changed more than once
  # Parse for the lines of code changed in each file and store them in a hash as the value to the corresponding filename key
  # Compare for same lines being changed in the keys of this hash
  # If there is a match, save the the PR name (the frist element in changed_files_list) as the key in resulting_pull_requests_with_link
  # and the current rails_pr_url being used in this iteration as it's value.
  # else if no matching lines of code:
  rails_pr_id += 1
  sleep 2
end

return resulting_pull_requests_with_link
