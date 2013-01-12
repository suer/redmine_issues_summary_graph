class IssuesSummaryGraphController < ApplicationController
  unloadable
  include IssuesSummaryGraphHelper
  before_filter :find_project

  DEFAULT_START_DATE = 6.month.ago

  def show
    @from = params[:from] || DEFAULT_START_DATE.strftime('%Y-%m-%d')
    @to = params[:to] || Date.today.strftime('%Y-%m-%d')
    if params[:closed_status_ids] 
      @closed_status_ids = params[:closed_status_ids].map {|id| id.to_i}
    else
      @closed_status_ids = IssueStatus.find(:all, :conditions => {:is_closed => true}).map {|status| status.id}
    end
  end

  def summary_graph
    from = params[:from] || DEFAULT_START_DATE.strftime('%Y-%m-%d')
    to = params[:to] || Date.today.strftime('%Y-%m-%d')
    closed_status_ids = params[:closed_issue_statuses].map {|id| id.to_i }
    image = generate_summary_graph(closed_status_ids, from, to)
    respond_to do |format|
      format.png  { send_data(image, :disposition => 'inline', :type => 'image/png', :filename => "summary.png") }
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
