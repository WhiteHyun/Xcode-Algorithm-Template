#!/bin/bash

# Extract the title-slug from the LeetCode URL
function extract_problem_name() {
  local url="$1"
  echo "$url" | sed -n 's/.*problems\/\(.*\)\/description.*/\1/p'
}

# Create the Swift code snippet
function create_swift_code_snippet() {
  local json_data="$1"
  local question_id="$2"
  local swift_code
  swift_code=$(echo -E "$json_data" | jq -r '.data.question.codeSnippets[] | select(.lang == "Swift") | .code')
  swift_code=$(echo "$swift_code" | sed '1d;$d')
  echo "$swift_code"
}

# GraphQL query to fetch problem details
function make_query() {
  local question_slug=$1
  local query='{
  "query": "query selectProblem($titleSlug: String!) { question(titleSlug: $titleSlug) { questionId title titleSlug difficulty exampleTestcases codeSnippets { lang langSlug code } } }",
  "variables": {
    "titleSlug": "'"$question_slug"'"
  }
}'
  echo "$query"
}

# Send a POST request to the LeetCode GraphQL API
function request() {
  local response
  response=$(curl -s -X POST -H "Content-Type: application/json" --data "$query" https://leetcode.com/graphql)
  echo -E "$response"
}

# Create a Swift file for the LeetCode problem
create_swift_file() {
  local json_data="$1"
  local question_id
  local difficulty
  local title
  local title_slug
  local swift_code
  local file_name
  local content

  question_id=$(echo -E "$json_data" | jq -r '.data.question.questionId')
  difficulty=$(echo -E "$json_data" | jq -r '.data.question.difficulty')
  title=$(echo -E "$json_data" | jq -r '.data.question.title')
  title_slug=$(echo -E "$json_data" | jq -r '.data.question.titleSlug')

  # Generate code snippet
  swift_code=$(create_swift_code_snippet "$json_data" "$question_id")
  file_name="${question_id}. ${title}"

  # Generate whole swift code
  content=$(make_solution_code "$question_id" "$title" "https://leetcode.com/problems/$title_slug/description/" "LeetCode" "$swift_code")

  # save file
  save_swift_file "$file_name" "$difficulty" "LeetCode" "$content"

  # link to xcodeproj
  add_to_xcode_project "$file_name" "LeetCode" "$difficulty"
}
