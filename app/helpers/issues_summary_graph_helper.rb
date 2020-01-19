module IssuesSummaryGraphHelper
  SUMMARY_IMAGE_WIDTH = 600
  SUMMARY_IMAGE_HEIGHT = 300
  LINE_NUM = 10
  PADDING = 40
  COLOR_ALL = '#ffb6c1'
  COLOR_CLOSED = '#aae'

  def generate_summary_graph(closed_issue_status_ids, tracker_ids, version_ids, from, to)
    closed_issue_map = {}
    open_issue_map = {}
    total_issue_num = 0

    date_from = to_date(from)
    date_to = to_date(to)


    @projects.each do |project|
      issues = project.issues

      if version_ids.include? 0
        issues = issues.where("fixed_version_id IS NULL OR fixed_version_id IN (?)", version_ids)
      else
        issues = issues.where("fixed_version_id IN (?)", version_ids)
      end

      issues = issues.where("created_on >= ?", date_from.beginning_of_day) unless date_from.nil?
      issues = issues.where("created_on <= ?", date_to.end_of_day) unless date_to.nil?

      issues = issues.where("tracker_id IN (?)", tracker_ids)

      issues.each do |issue|
        open_issue_map[issue.created_on.strftime('%Y%m%d')] ||= 0
        open_issue_map[issue.created_on.strftime('%Y%m%d')] += 1

        closed_date = issue_closed_date(issue, closed_issue_status_ids)
        if closed_date
          closed_issue_map[closed_date.strftime('%Y%m%d')] ||= 0
          closed_issue_map[closed_date.strftime('%Y%m%d')] += 1
        end
      end
      total_issue_num += issues.size
    end
    sorted_open_issue_map = open_issue_map.sort
    sorted_closed_issue_map = closed_issue_map.sort
    if sorted_open_issue_map.length == 0 and sorted_closed_issue_map.length == 0
      imgl = Magick::ImageList.new
      imgl.new_image(SUMMARY_IMAGE_WIDTH, SUMMARY_IMAGE_HEIGHT)
      gc = Magick::Draw.new
      gc.stroke('transparent')
      gc.fill('black')
      gc.draw(imgl)
      imgl.format = 'PNG'
      return imgl.to_blob
    end

    if sorted_open_issue_map.length == 0
      start_date = Date.parse(sorted_closed_issue_map[0][0])
      end_date = Date.parse(sorted_closed_issue_map[-1][0])
    elsif sorted_closed_issue_map.length == 0
      start_date = Date.parse(sorted_open_issue_map[0][0])
      end_date = Date.parse(sorted_open_issue_map[-1][0])
    else
      start_date = Date.parse((sorted_open_issue_map[0][0] < sorted_closed_issue_map[0][0]) ? sorted_open_issue_map[0][0] : sorted_closed_issue_map[0][0])
      end_date = Date.parse((sorted_open_issue_map[-1][0] > sorted_closed_issue_map[-1][0]) ? sorted_open_issue_map[-1][0] : sorted_closed_issue_map[-1][0])
    end
    duration = (end_date - start_date)
    draw_summary_graph(start_date, total_issue_num, open_issue_map, closed_issue_map, duration)
  end

  def draw_summary_graph(start_date, total_issue_num, open_issue_map,  closed_issue_map, duration)
    imgl = Magick::ImageList.new
    imgl.new_image(SUMMARY_IMAGE_WIDTH, SUMMARY_IMAGE_HEIGHT)
    gc = Magick::Draw.new
    gc.stroke('transparent')
    gc.fill('black')
    border(gc, total_issue_num)
    draw_line(open_issue_map, start_date, duration, gc, COLOR_ALL, total_issue_num)
    draw_line(closed_issue_map, start_date, duration, gc, COLOR_CLOSED, total_issue_num)
    gc.stroke('transparent').fill('black').text(PADDING + 45, 25, 'all').text(PADDING + 45, 45, 'closed')
    gc.stroke(COLOR_ALL).stroke_width(3).fill(COLOR_ALL).line(PADDING + 10, 20, PADDING + 40, 20)
    gc.stroke(COLOR_CLOSED).stroke_width(3).fill(COLOR_CLOSED).line(PADDING + 10, 40, PADDING + 40, 40)

    gc.draw(imgl)
    imgl.format = 'PNG'
    imgl.to_blob
  end

  def draw_line(issue_map, start_date, duration, gc, color, issue_num)
    top_issue_num = border_step(issue_num) * LINE_NUM
    x_base = PADDING
    y_base = SUMMARY_IMAGE_HEIGHT - PADDING
    x = x_base
    y = y_base
    prev_x = x
    prev_y = y
    sum = 0
    (duration + 1).to_i.times do |i|
      x += ((SUMMARY_IMAGE_WIDTH - PADDING * 2) / (duration + 1))
      sum += issue_map[(start_date + i).strftime('%Y%m%d')] || 0
      if issue_map[(start_date + i).strftime('%Y%m%d')]
        y = y_base.to_f * (1 - (sum.to_f / top_issue_num.to_f))
      end
      if (start_date + i).strftime('%d') == '01'
        gc.stroke('transparent').stroke_width(1)
        gc.fill('black').text(x.to_i - 20, SUMMARY_IMAGE_HEIGHT - 20, (start_date + i).strftime('%Y/%m'))
        gc.fill('lightgray').line(x.to_i, 0, x.to_i, y_base)
      end

      gc.fill(color)
      gc.line(prev_x, prev_y, x, y)
      gc.fill_opacity(0.5)
      (prev_x.floor + 1).upto(x.floor) do |tmp_x|
        tmp_y = (prev_y - y) / (prev_x - x) * tmp_x + y - (prev_y - y) / (prev_x - x) * x
        gc.stroke('transparent').stroke_width(1).line(tmp_x, tmp_y, tmp_x, y_base)
      end
      gc.fill_opacity(1.0)
      gc.stroke(color).stroke_width(2).fill(color).line(prev_x, prev_y, x, y)
      prev_x = x
      prev_y = y
    end
  end

  def border(gc, issue_num)
    graph_height = SUMMARY_IMAGE_HEIGHT - PADDING
    graph_width = SUMMARY_IMAGE_WIDTH- PADDING
    margin = (graph_height / LINE_NUM).to_i
    step = border_step(issue_num)
    (LINE_NUM + 1).times do |i|
      height = (i == 0 ? (graph_height - 1) : ((graph_height - PADDING) / LINE_NUM) * i)
      gc.stroke('transparent').stroke_width(1).fill('lightgray')
      gc.line(PADDING, graph_height - margin * i + 1, graph_width, graph_height - margin * i)
      gc.stroke('transparent').stroke_width(1).fill('black')
      text = (step * i).to_i.to_s
      metrics = gc.get_type_metrics(text)
      text_height = (metrics.bounds.y2 - metrics.bounds.y1).round
      gc.text(0, graph_height - margin * i + text_height, text)
    end
    gc.stroke('transparent').fill('lightgray')
    gc.line(PADDING, graph_height - 1, graph_width, graph_height - 1)
    gc.stroke('transparent').fill('lightgray').line(PADDING, 0, PADDING, graph_height)
    gc.line(graph_width, 0, graph_width, graph_height)
  end

  def border_step(issue_num)
    return 1 if issue_num <= 10
    digit = issue_num.to_s.size
    if digit == 2
      return 5 if issue_num <= 50
      return 10
    end
    if issue_num <= 2 * (10 ** (digit - 1))
      step = 10 ** (digit - 2)
    else
      step = 10 ** (digit - 1)
    end
    max = step * (issue_num / step)
    remainder = issue_num - (issue_num / step)
    if remainder != 0
      max = max + step
    end
    return (max / 10)
  end

  def issue_closed_date(issue, closed_issue_status_ids)
    issue.journals.each do |journal|
      if journal.details.size == 0
        return (closed_issue_status_ids.include?(issue.status.id) ? issue.updated_on : nil)
      end
      journal.details.each do |detail|
        next unless detail.prop_key == 'status_id'
        if closed_issue_status_ids.include?(detail.value.to_i)
          return journal.created_on
        end
      end
    end
    closed_issue_status_ids.include?(issue.status.id) ? issue.updated_on : nil
  end

  def to_date(str)
    return nil if str.blank?

    begin
      str.to_date
    rescue
      nil
    end
  end

end
