module IssuesSummaryGraphHelper
  SUMMARY_IMAGE_WIDTH = 600
  SUMMARY_IMAGE_HEIGHT = 300
  LINE_NUM = 10
  PADDING = 40

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

    gc.draw(imgl)
    imgl.format = 'PNG'
    imgl.to_blob
  end

  def draw_line(issue_map, start_date, duration, gc, color, issue_num)
    top_issue_num = border_step(issue_num) * LINE_NUM
    x = PADDING
    y = SUMMARY_IMAGE_HEIGHT - PADDING
    prev_x = PADDING
    prev_y = SUMMARY_IMAGE_HEIGHT - PADDING
    sum = 0
    (duration + 1).to_i.times do |i|
      x += ((SUMMARY_IMAGE_WIDTH - PADDING * 2) / (duration + 1))
      sum += issue_map[(start_date + i).strftime('%Y%m%d')] || 0
      if issue_map[(start_date + i).strftime('%Y%m%d')]
        y = (SUMMARY_IMAGE_HEIGHT - PADDING).to_f * (1 - (sum.to_f / top_issue_num.to_f))
      end
      gc.fill(color)
      gc.line(prev_x, prev_y, x, y)
      if (start_date + i).strftime('%d') == '01'
        gc.fill('black')
        gc.text(x.to_i - 20, SUMMARY_IMAGE_HEIGHT - 20, (start_date + i).strftime('%Y/%m')) 
        gc.fill('lightgray')
        gc.line(x.to_i, 0, x.to_i, SUMMARY_IMAGE_HEIGHT - PADDING)
      end
      prev_x = x
      prev_y = y
    end
  end

  def border(gc, issue_num)
    margin = ((SUMMARY_IMAGE_HEIGHT - PADDING) / LINE_NUM).to_i
    step = border_step(issue_num)
    (LINE_NUM + 1).times do |i|
      height = (i == 0 ? (SUMMARY_IMAGE_HEIGHT - PADDING - 1) : ((SUMMARY_IMAGE_HEIGHT - PADDING * 2) / LINE_NUM) * i)
      gc.fill('lightgray')
      gc.line(PADDING, (SUMMARY_IMAGE_HEIGHT - PADDING) - margin * i + 1, SUMMARY_IMAGE_WIDTH - PADDING, (SUMMARY_IMAGE_HEIGHT - PADDING) - margin * i)
      gc.fill('black')
      gc.text(0, (SUMMARY_IMAGE_HEIGHT - PADDING) - margin * i, (step * i).to_i.to_s) if i != LINE_NUM
    end
    gc.fill('lightgray')
    gc.line(PADDING, (SUMMARY_IMAGE_HEIGHT - PADDING) - 1, SUMMARY_IMAGE_WIDTH - PADDING, (SUMMARY_IMAGE_HEIGHT - PADDING) - 1)
    gc.fill('black')
    gc.text(0, (SUMMARY_IMAGE_HEIGHT - PADDING) - 1, '0')
    gc.fill('lightgray')
    gc.line(PADDING, 0, PADDING, (SUMMARY_IMAGE_HEIGHT - PADDING))
    gc.line(SUMMARY_IMAGE_WIDTH - PADDING, 0, SUMMARY_IMAGE_WIDTH- PADDING, (SUMMARY_IMAGE_HEIGHT - PADDING))
  end

  def border_step(issue_num)
    return 1 if issue_num.to_s.size == 1
    if issue_num.to_s.size == 2
      return 5 if issue_num <= 50
      return 10
    end
    upper_double_digit = (issue_num.to_f / (10 ** (issue_num.to_s.size - 2)).to_f).ceil
    if upper_double_digit % 10 == 0
      upper_double_digit / 10
    elsif upper_double_digit % 10 <= 5
      upper_double_digit / 10 * 10 + 5
    else
      upper_double_digit / 10 * 10 + 10
    end
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
