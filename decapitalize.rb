module Decapitalize
    def decapitalize(country_or_region)
    country_or_region_dup = country_or_region.dup
    country_or_region.scan(/([A-Z]+)/).each do |word|
      word = word.first

      next if ( word == 'USSR' || word == 'PRC' )

      new_word = word.downcase
      new_word = new_word.capitalize unless ( new_word == "of" || new_word == "and" )

      country_or_region_dup.sub!(word, new_word)
    end

    return country_or_region_dup
  end
end