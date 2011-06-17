class IssuesSummaryGraphController < ApplicationController
  unloadable
  include IssuesSummaryGraphHelper
  before_filter :find_project

  def show
  end

  def summary_graph
    respond_to do |format|
      format.png  { send_data(generate_summary_graph, :disposition => 'inline', :type => 'image/png', :filename => "summary.png") }
    end
  end

  private
  def find_project
    project_id = (params[:issue] && params[:issue][:project_id]) || params[:project_id]
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
