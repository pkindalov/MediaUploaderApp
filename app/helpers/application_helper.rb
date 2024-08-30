module ApplicationHelper
  def render_folders(folders, level = 0, parent_id = nil)
    folders.select { |folder| folder.parent_id == parent_id }.map do |folder|
      render_folder_item(folder, level) + render_folders(folders, level + 1, folder.id)
    end.join.html_safe
  end

  def render_folder_item(folder, level)
    content_tag(:li, class: 'list-group-item d-flex justify-content-between align-items-center') do
      concat(
        content_tag(:div) do
          concat(link_to("#{'-' * level} #{folder.name}", folder_media_files_path(folder), class: 'nav-link d-inline text-primary'))
          concat(content_tag(:small, "(#{folder.media_files.count} файла)", class: 'text-muted'))
        end
      )
      concat(
        content_tag(:div, class: 'btn-group', role: 'group') do
          concat(link_to(edit_folder_path(folder), class: 'btn btn-secondary btn-sm') do
            concat(content_tag(:i, '', class: 'fa-solid fa-pen-to-square'))
            concat ' Редактирай'
          end)
          concat(link_to(folder_path(folder), method: :delete, data: { confirm: 'Сигурни ли сте (това ще изтрие и съдържанието на папката)?' }, class: 'btn btn-danger btn-sm') do
            concat(content_tag(:i, '', class: 'fa-solid fa-trash'))
            concat ' Изтрий'
          end)
        end
      )
    end
  end

  def nested_folders_options(folders, parent_id = nil, level = 0, exclude_folder = nil)
    result = []

    folders.select { |folder| folder.parent_id == parent_id && folder != exclude_folder }.each do |folder|
      result << ["#{"-" * level} #{folder.name}", folder.id]
      result += nested_folders_options(folders, folder.id, level + 1, exclude_folder)
    end

    result
  end


  def folder_hierarchy_name(folder, level = 0)
    "#{'-' * level} #{folder.name}".strip
  end

end
