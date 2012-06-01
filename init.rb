require 'redmine'

Redmine::Plugin.register :redmine_issues_summary_graph do
  name 'Redmine Issues Summary Graph plugin'
  author 'suer'
  description 'issues summary graph'
  version '0.0.3'
  url 'https://github.com/suer/redmine_issues_summary_graph'
  author_url 'http://d.hatena.ne.jp/suer'

  project_module :issues_summary_graph do
    permission :issues_summary_graph, {:issues_summary_graph => [:show]}, :public => true
    menu :project_menu, :issues_summary_graph, {:controller => 'issues_summary_graph', :action => 'show'},
    :caption => :menu_issues_summary_graph, :param => :project_id
  end

end
