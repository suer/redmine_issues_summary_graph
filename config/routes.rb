ActionController::Routing::Routes.draw do |map|
  map.connect 'issues_summary_graph/:project_id/:action.:format', :controller => 'issues_summary_graph'
end
