require 'open-uri'
require 'nokogiri'

PR_ELEMENT_PATH = 'div.Box.mt-3.Box--responsive.hx_Box--firstRowRounded0 > div:nth-child(2) > div > div > div > div:nth-child(2) > a'

### FIRST: GET THE LAST LINK (THE NEWEST PULL REQUEST). SO WE KNOW WHEN TO BREAK OUR LOOP BELOW
def find_last_pr_url
  # This link will always produce the last PR link at the top of the list - regardless of new PRs being opened
  url = "https://github.com/rails/rails/pulls?q=is%3Apr+sort%3Acreated-desc"
  pr_index_page_document = Nokogiri::HTML(URI.open(url).read)
  # Must reach from much larger parent element and include 'div > div > div' because at that point
  # the quickest identification is by ID, which has a dynamic value we cannot use this to grab an
  # element in the first position that we know will change
  last_pr_url = pr_index_page_document.search(PR_ELEMENT_PATH).first['href']
end

### SECOND: LOOP THROUGH INDEX OF PULL REQUEST PAGES TO GET THE HREF FOR EACH LINK
def get_pr_links(index_page_number)
  all_pr_links = []

  loop do
    # We start form the frist PR and go toward the last - the base url is 'created-asc'
    # I tried to add a 'limit=100' parameter in the url to show 100 records instead of just 25,
    # decreasing the number of pages to loop through, but it wasnt accepted.
    base_url = "https://github.com/rails/rails/pulls?page=#{index_page_number}&q=is%3Apr+sort%3Acreated-asc"
    current_index_doc = Nokogiri::HTML(URI.open(base_url).read)
    urls_on_current_index = current_index_doc.search(PR_ELEMENT_PATH).map { |element| element['href'] }
    all_pr_links += urls_on_current_index
    break if all_pr_links.last == find_last_pr_url
    index_page_number += 1
    sleep 3
  end
  all_pr_links
end

### Test below to confirm the loop breaks where it should - starts on second to last page (1122)
### so as not to run through all the index pages.

# puts get_pr_links(1122)
