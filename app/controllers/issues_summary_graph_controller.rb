class IssuesSummaryGraphController < ApplicationController
  unloadable
  include IssuesSummaryGraphHelper
  before_filter :find_project

  def show
    if params[:closed_status_ids] 
      @closed_status_ids = params[:closed_status_ids].map {|id| id.to_i}
    else
      @closed_status_ids = IssueStatus.find(:all, :conditions => {:is_closed => true}).map {|status| status.id}
    end
  end

  def summary_graph
    closed_status_ids = params[:closed_issue_statuses].map {|id| id.to_i }
    respond_to do |format|
      format.png  { send_data(generate_summary_graph(closed_status_ids), :disposition => 'inline', :type => 'image/png', :filename => "summary.png") }
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
