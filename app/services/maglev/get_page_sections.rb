# frozen_string_literal: true

module Maglev
  class GetPageSections
    include Injectable

    dependency :fetch_site
    dependency :fetch_theme
    dependency :get_page_fullpath

    argument :page

    def call
      page.sections.map do |section|
        transform_section(section.dup)
      end
    end

    protected

    def theme
      fetch_theme.call
    end

    def site
      fetch_site.call
    end

    # rubocop:disable Style/StringHashKeys
    def transform_section(section)
      definition = theme.sections.find(section['type'])
      site_section = site.find_section(section['type'])

      if definition.scoped_by_site? && site_section
        section.merge!('settings' => site_section['settings'], 'blocks' => site_section['blocks'])
      end

      transform_section_blocks(section['blocks'], definition)
      transform_section_settings(section, definition)

      section
    end
    # rubocop:enable Style/StringHashKeys

    def transform_section_blocks(blocks, definition)
      blocks.each do |block|
        block_definition = definition.blocks.find { |bd| bd.type == block['type'] }
        next unless block_definition

        transform_section_settings(block, block_definition)
      end
    end

    def transform_section_settings(section, definition)
      definition.settings.each do |setting|
        section_setting = find_section_setting(section, setting.id)
        next unless section_setting

        transform_content_setting(section_setting, setting)
      end
    end

    def transform_content_setting(content, setting)
      case setting.type
      when 'link'
        return unless content['value'].is_a?(Hash) && content.dig('value', 'link_type') == 'page'

        content['value'] = replace_href_in_link(content['value'])
      when 'text'
        return unless setting.options['html']

        content['value'] = replace_links_in_text(content['value'])
      end
    end

    def find_section_setting(section, setting_id)
      section['settings'].find { |setting| setting['id'] == setting_id }
    end

    def replace_href_in_link(link)
      path = get_page_fullpath.call(page: link['link_id'])
      if path
        anchor = link['section_id']
        link['href'] = anchor.present? ? "#{path}##{anchor}" : path
      end
      link
    end

    def replace_links_in_text(text)
      text.gsub(/<a([^>]+)>/) do |tag|
        link_type_matches = tag.match(/maglev-link-type="([^"]+)"/)
        link_id_matches = tag.match(/maglev-link-id="([^"]+)"/)
        section_id_matches = tag.match(/maglev-section-id="([^"]+)"/)
        path = find_link_page_path(link_type_matches, link_id_matches, section_id_matches)

        tag.gsub!(/href="([^"]+)"/, "href=\"#{path}\"") if path

        tag
      end
    end

    def find_link_page_path(link_type_matches, link_id_matches, section_id_matches)
      return unless link_type_matches && link_id_matches && link_type_matches[1] == 'page'

      path = get_page_fullpath.call(page: link_id_matches[1])
      anchor = section_id_matches ? section_id_matches[1] : nil
      anchor.present? ? "#{path}##{anchor}" : path
    end
  end
end