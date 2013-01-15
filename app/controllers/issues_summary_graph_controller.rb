class IssuesSummaryGraphController < ApplicationController
  unloadable
  include IssuesSummaryGraphHelper
  before_filter :find_projects

  DEFAULT_START_DATE = 6.month.ago

  def show
    @from = params[:from]
    @from = DEFAULT_START_DATE.strftime('%Y-%m-%d') if @from.blank? and request.get?

    @to = params[:to]
    @to = Date.today.strftime('%Y-%m-%d') if @to.blank? and request.get?

    @include_subproject = (params[:include_subproject].blank? ? false : true)

    if params[:closed_status_ids]
      @closed_status_ids = params[:closed_status_ids].map {|id| id.to_i}
    else
      @closed_status_ids = IssueStatus.find(:all, :conditions => {:is_closed => true}).map {|status| status.id}
    end
  end

  def summary_graph
    closed_status_ids = params[:closed_issue_statuses].map {|id| id.to_i }
    image = generate_summary_graph(closed_status_ids, params[:from], params[:to])
    respond_to do |format|
      format.png  { send_data(image, :disposition => 'inline', :type => 'image/png', :filename => "summary.png") }
    end
  end

  private
  def find_projects
    project_id = (params[:issue] && params[:issue][:project_id]) || params[:project_id]
    @project = Project.find(project_id)
    @projects = [@project]
    @projects += @project.descendants if to_boolean(params[:include_subproject])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def to_boolean(str)
    return false if str.blank?
    str.to_s == 'true'
  end
end
