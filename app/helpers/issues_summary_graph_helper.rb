module IssuesSummaryGraphHelper
  SUMMARY_IMAGE_WIDTH = 600
  SUMMARY_IMAGE_HEIGHT = 200
  LINE_NUM = 10
  PADDING_LEFT = 40

  def generate_summary_graph
    imgl = Magick::ImageList.new
    imgl.new_image(SUMMARY_IMAGE_WIDTH, SUMMARY_IMAGE_HEIGHT)
    gc = Magick::Draw.new

    gc.stroke('transparent')
    gc.fill('black')
    closed_issue_status_ids = IssueStatus.find(:all, :conditions => ['is_closed = ?', true]).map {|st| st.id}
    closed_issue_map = {}
    open_issue_map = {}
    issues = @project.issues
    issues.each do |issue|
      open_issue_map[issue.created_on.strftime('%Y%m%d')] ||= 0
      open_issue_map[issue.created_on.strftime('%Y%m%d')] += 1 

      closed_date = issue_closed_date(issue, closed_issue_status_ids)
      if closed_date
        closed_issue_map[closed_date.strftime('%Y%m%d')] ||= 0
        closed_issue_map[closed_date.strftime('%Y%m%d')] += 1
      end      
    end

    sorted_open_issue_map = open_issue_map.sort
    sorted_closed_issue_map = closed_issue_map.sort
    if sorted_open_issue_map.length == 0 and sorted_closed_issue_map.length == 0
      gc.draw(imgl)
      imgl.format = 'PNG'
      return imgl.to_blob
    end
    
    if sorted_open_issue_map.length == 0
      start_date = Date.parse(sorted_closed_issue_map[0][0])
      end_date = Date.parse(sorted_closed_issue_map[-1][0])
    elsif sorted_closed_issue_map.length == 0 
      start_date = Date.parse(sorted_sorted_open_issue_map[0][0])
      end_date = Date.parse(sorted_open_issue_map[-1][0])
    else
      start_date = Date.parse((sorted_open_issue_map[0][0] < sorted_closed_issue_map[0][0]) ? sorted_open_issue_map[0][0] : sorted_closed_issue_map[0][0])
      end_date = Date.parse((sorted_open_issue_map[-1][0] > sorted_closed_issue_map[-1][0]) ? sorted_open_issue_map[-1][0] : sorted_closed_issue_map[-1][0])
    end
    duration = ((end_date - start_date))

    draw_line(open_issue_map, start_date, duration, gc, 'red', issues.size)
    draw_line(closed_issue_map, start_date, duration, gc, 'black', issues.size)
    border(gc, issues.size)

    closed_issue_map.each do |key, value|
      logger.info "#{key} #{value}"
    end

    gc.draw(imgl)
    imgl.format = 'PNG'
    imgl.to_blob
  end

  def draw_line(issue_map, start_date, duration, gc, color, issue_num)
    gc.fill(color)
    x = PADDING_LEFT
    y = SUMMARY_IMAGE_HEIGHT
    prev_x = PADDING_LEFT
    prev_y = SUMMARY_IMAGE_HEIGHT
    sum = 0
    (duration + 1).to_i.times do |i|
      x += ((SUMMARY_IMAGE_WIDTH - PADDING_LEFT) / (duration + 1))
      sum += issue_map[(start_date + i).strftime('%Y%m%d')] || 0
      if issue_map[(start_date + i).strftime('%Y%m%d')]
        y = SUMMARY_IMAGE_HEIGHT.to_f * (1 - (sum.to_f / issue_num.to_f))
      end
      gc.line(prev_x, prev_y, x, y)
      prev_x = x
      prev_y = y
    end
  end

  def border(gc, issue_num)
    logger.info (issue_num / LINE_NUM).to_i
    logger.info (10 ** (issue_num / LINE_NUM).to_i.to_s.size - 1)
    margin = ((issue_num / LINE_NUM).to_i + (10 ** ((issue_num / LINE_NUM).to_i.to_s.size - 1))) * (10 ** ((issue_num / LINE_NUM).to_i.to_s.size ))
    step = (issue_num / LINE_NUM).to_i + 10 ** ((issue_num / LINE_NUM).to_i.to_s.size - 1)

    gc.fill('lightgray')
    gc.line(PADDING_LEFT, 1, SUMMARY_IMAGE_WIDTH, 1)
    gc.fill('black')
    gc.text(0, 1, issue_num.to_s)
    LINE_NUM.times do |i|
      height = (i == 0 ? (SUMMARY_IMAGE_HEIGHT-1) : (SUMMARY_IMAGE_HEIGHT / LINE_NUM) * i)
      gc.fill('lightgray')
      gc.line(PADDING_LEFT, SUMMARY_IMAGE_HEIGHT - margin * i, SUMMARY_IMAGE_WIDTH, SUMMARY_IMAGE_HEIGHT - margin * i)
      gc.fill('black')
      logger.info "#{issue_num} * #{margin} / #{SUMMARY_IMAGE_HEIGHT}"
      gc.text(0, SUMMARY_IMAGE_HEIGHT - margin * i, (step * i).to_i.to_s)
    end
    gc.fill('lightgray')
    gc.line(PADDING_LEFT, SUMMARY_IMAGE_HEIGHT - 1, SUMMARY_IMAGE_WIDTH, SUMMARY_IMAGE_HEIGHT - 1)
    gc.fill('black')
    gc.text(0, SUMMARY_IMAGE_HEIGHT - 1, '0')
  end

  def issue_closed_date(issue, closed_issue_status_ids)
    issue.journals.each do |journal|
      journal.details.each do |detail|
        next unless detail.prop_key == 'status_id'
        if closed_issue_status_ids.include?(detail.value.to_i)
          return journal.created_on
        end
      end
    end
    nil
  end
end
