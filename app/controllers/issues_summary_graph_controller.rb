class IssuesSummaryGraphController < ApplicationController
  unloadable

  before_filter :find_project

  def show
  end

  def summary_graph
    respond_to do |format|
      format.png  { send_data(generate_summary_graph, :disposition => 'inline', :type => 'image/png', :filename => "summary.png") }
    end
  end

  private
  def generate_summary_graph
    imgl = Magick::ImageList.new
    imgl.new_image(240, 200)
    gc = Magick::Draw.new

    gc.stroke('transparent')
    gc.fill('black')

    # gc.line(0, 0, 240, 200)

    closed_issue_ids = IssueStatus.find(:all, :conditions => ['is_closed = ?', true]).map {|st| st.id}
    closed_issue_ids.each do |id|
      logger.info id
    end

    closed_issue_map = {}
    open_issue_map = {}
    issues = @project.issues
    issues.each do |issue|
      open_issue_map[issue.created_on.beginning_of_day] ||= 0
      open_issue_map[issue.created_on.beginning_of_day] += 1 
      issue.journals.each do |journal|
        journal.details.each do |detail|
          next unless detail.prop_key == 'status_id'
          if closed_issue_ids.include?(detail.value.to_i)
            closed_issue_map[journal.created_on.beginning_of_day] ||= 0
            closed_issue_map[journal.created_on.beginning_of_day] += 1
          end
        end
      end
    end

    x = 0
    y = 200
    prev_x = 0
    prev_y = 200
    closed_issue_map.each do |key, value|
      x += 20
      y -= value
      gc.line(prev_x, prev_y, x, y)
      prev_x = x
      prev_y = y
    end

    x = 0
    y = 200
    prev_x = 0
    prev_y = 200
    gc.fill('red')
    open_issue_map.each do |key, value|
      x += 20
      y -= value
      gc.line(prev_x, prev_y, x, y)
      prev_x = x
      prev_y = y
    end


    gc.draw(imgl)
    imgl.format = 'PNG'
    imgl.to_blob
  end

  def find_project
    project_id = (params[:issue] && params[:issue][:project_id]) || params[:project_id]
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end


end
