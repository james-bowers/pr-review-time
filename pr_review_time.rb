require 'octokit'
require 'time'
require 'descriptive_statistics'

ONE_HOUR = 3600
WORK_HOURS_PER_DAY = 8
HOURS_IN_A_DAY = 24
REPO = ARGV[0]

access_token = File.read(".github_secret_token")

Octokit.auto_paginate = true
client = Octokit::Client.new(:access_token => access_token)

pull_requests = client.pull_requests(REPO, :state => 'closed')

def statistics(hours)
%Q(
Unit = BBC working hours.

Median     #{hours.median.round}
50th       #{hours.percentile(50).round}
70th       #{hours.percentile(70).round}
80th       #{hours.percentile(80).round}
90th       #{hours.percentile(90).round}
99th       #{hours.percentile(99).round}

Assumptions:
- Weekends do not exist.
)
end

def convert_hours_to_work_hours(hours)
  hours.map do |total_pr_duration|
    days = total_pr_duration / HOURS_IN_A_DAY
    days * WORK_HOURS_PER_DAY
  end
end

def total_pr_duration(prs)
  prs.map do |pr|
    # TODO: take into account weekends
    ((pr.merged_at - pr.created_at) / ONE_HOUR)
  end
end

merged_pull_requests = pull_requests.select {|pr| pr.merged_at }

total_hours_duration = total_pr_duration(merged_pull_requests)
work_hours_duration = convert_hours_to_work_hours(total_hours_duration)

p "#{merged_pull_requests.length} merged PRs in #{REPO}."
print statistics(work_hours_duration)