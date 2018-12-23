%w(show summary_graph).each do |action|
  match "issues_summary_graph/:project_id/#{action}(.:format)", controller: 'issues_summary_graph', action: action, via: [:get, :post]
end
