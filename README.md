# pr_with_edited_commits

PROMPT:
Crawl the rails/rails github repo and list all the pull requests where there are rows in files
affected by multiple commits. Please provide links to the specific rows as well.
____________________________________________________________________________________________

My solution is made up of 3 main parts:
1. fetching the URL for all pull requests in the rails/rails repo - represented in the pr_links.rb file.
2. parsing the HTML from each pull request link gathered in step one to create a data structure (JSON), allowing for easier comparison of data. The structure
   created looks like this below:
   
   ```
   
   {
      "PR_title": "Sample pull request title for example",
      "commits": [
        {
          "commit_title": "fix this and merge that",
          "commit_url": " "'https://github.com/rails/rails/pull/43240/commits/d07a101183bc97d0ff4507ff592f74f303997d7f"
          "files": [
            {
              "filename": "activerecord/lib/active_record/railties/databases.rake",
              "file_url": "https://github.com/rails/rails/pull/43240/commits/d07a101183bc97d0ff4507ff592f74f303997d7f#diff-4a42b5efdab725af0936f94b4a84dcf6a8be8738e28ed265e0a3e74f275f5048",
              "changed_lines": [-498, -618, -619, -663, -665, 498, 618, 619, 664, 665]
            },
            {
              "filename": "activerecord/lib/active_record/tasks/database_tasks.rb",
              "file_url": "https://github.com/rails/rails/pull/43240/commits/d07a101183bc97d0ff4507ff592f74f303997d7f#diff-cb5c658a1aa7877862198142775880b76b1d327ade6fd39f7c29a080535de6b7",
              "changed_lines": [-216, -222, -225, -380, -402, -411, -423, -424, -430, -434, -438, -441, -497, -499, 216, 222, 379, 380, 402, 411, 423, 424]
            }
          ]
        }
      ]
    }
    
    ```
    negative changed lines are, of course, not negative lines of code, but represent deletions from the file. positive line numbers are additions.
  
3. Reviewing the data just parsed and organized from the html and determining if there are files that have lines of code changed in more than one commit within the pull request.


While I am familiar with rspec, can read and understand already written tests, 
and can run rake to execute rspec tests and understand the terminal output,
I am unable to write rspec tests at this time (have not learned yet).
For this reason I cannot properly test my code.

I also cannot run it as it would take tens of hours to complete, with more thank 27,000 PRs to check in the rails repo.

HOWEVER - I have run and tested each block of code which makes up this complete algorithm and can confirm that it works - to the best of my abilities.

I've run the whole script for the test case with `pr_url = '/rails/rails/pull/43240'` which actually is a pull request that meets the criteria of the prompt
and returns an array with PR title and relevant links: 
```

[ 
  'Override schema_format per database via configuration', 
  'https://github.com/rails/rails/pull/43240/commits/d07a101183bc97d0ff4507ff592f74f303997d7f#diff-cb5c658a1aa7877862198142775880b76b1d327ade6fd39f7c29a080535de6b7R498',
  'https://github.com/rails/rails/pull/43240/commits/d07a101183bc97d0ff4507ff592f74f303997d7f#diff-cb5c658a1aa7877862198142775880b76b1d327ade6fd39f7c29a080535de6b7R500'
]

```
