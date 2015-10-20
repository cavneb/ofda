module OFDA
  module FdaSearchTermUtils

    def is_fda_safe?(c)
      !!(/^[a-zA-Z0-9-]$/ =~ c)
    end

    def make_fda_safe(search_term)
      return '' unless search_term && search_term.length > 0

      search_term = search_term.upcase
      safe_term = ''

      # whitelist special characters because many normal characters such as
      # commas can make FDA return HTTP 500 errors.
      last_space = true
      search_term.split('').each do |char|
        if is_fda_safe?(char)
          last_space = false
          safe_term << char
        elsif !last_space
          safe_term << ' '
          last_space = true
        end
      end

      safe_term.strip.gsub(' AND ', ' ')
    end
  end
end