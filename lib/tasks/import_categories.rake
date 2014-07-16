namespace :data do
  
  #--- category update end
  
  namespace :import do

    desc "create categories tree"
    task :categories => :environment do 
      puts 'importing categories..'
      CategoryContent.up
      puts 'done.'
    end
    
  end
  
  namespace :purge do

    desc "purges categories tree "
    task :categories => :environment do 
      puts 'purging categories..'
      CategoryContent.down
      puts 'done.'
    end

  end

  #--- begin update category class
  class CategoryContent
    # Root Categories:
    # - COMPANIES      -- Companies and Organizations
    # - MONEY          -- Money and Finance
    # - HEALTH         -- Health
    # - LEGAL          -- Law and Legal
    # - SOCIETY        -- Society and Culture

    @@tag_list_delimiter = nil
    def self.tag_list_delimiter
      @@tag_list_delimiter
    end
    
    def self.tag_list_delimiter=(value)
      @@tag_list_delimiter = value
    end
    
    @@tag_filter_active = nil
    def self.tag_filter_active
      @@tag_filter_active
    end
    
    def self.tag_filter_active=(value)
      @@tag_filer_active = value
    end
    
    @@translate_tags = nil
    def self.translate_tags
      @@translate_tags
    end
    
    def self.translate_tags=(value)
      @@translate_tags = value
    end

    ROOTS = [
      # Law and Legal
      { :name => "Law and Legal", :short_name => "Legal", :name_de => "Recht und Justiz", :short_name_de => "Recht", :children => [
        # civil law
        { :name => "Civil Law", :name_de => "Bürgerliches Recht", :children => [
          { :name => "Rent and Lease Agreements", :tags => "rental agreement lease leasing contract", :name_de => "Mietrecht", :tags_de => "Mietrecht Miete mieten vermieten Mietkaution Mietvertrag Vermieter Mieterschutz Miete Recht" },
          { :name => "Property Law", :tags => "land property properties chattels law", :name_de => "Sachenrecht", :tags_de => "Sachenrecht Anwesen Haus Häuser Grundstücksrecht Grundstücke Besitz Eigentum Verkaufsrecht Vorverkaufsrecht Hypothek Grundschuld Rentenschuld Dienstbarkeit" },
          { :name => "Law of Succession", :tags => "succession law testament 'last will' 'forced heirship' 'compulsory portion'", :name_de => "Erbrecht", :tags_de => "Erbrecht Erbe Recht Testament Erbfolge Erbvertrag Pflichtteilsrecht" },
          { :name => "Damages", :tags => "damage law damages house car" },
          { :name => "Privacy Law", :tags => "privacy law", :name_de => "Datenschutzrecht", :tags_de => "Daten Datenschutz Persönlichkeit persönlich Schutz Recht" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" }
        ] },
        # family law (extracted from civil law)
        { :name => "Family Law", :name_de => "Familienrecht", :children => [
          { :name => "Adoption", :tags => "adoption", :name_de => "Adoption", :tags_de => "Adoption" },
          { :name => "Child Custody and Visitation", :tags => "child custody visitation", :name_de => "Sorgerecht", :tags_de => "Sorgerecht Kind Besuchsrecht" },
          { :name => "Child Support", :tags => "child support", :name_de => "Kindesunterhalt", :tags_de => "Kindesunterhalt Unterhaltspflicht Unterhalt" },
          { :name => "Divorce", :tags => "divorce separation", :name_de => "Scheidung", :tags_de => "Scheidung Trennung" },
          { :name => "Paternity", :tags => "paternity", :name_de => "Vaterschaft", :tags_de => "Vaterschaft" },
          { :name => "Prenuptials", :tags => "prenuptials prenuptial marital property", :name_de => "Ehevertrag", :tags_de => "Ehevertrag Güterrecht Gütertrennung Zugewinngemeinschaft Gütergemeinschaft" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" }
        ] },
        # business and corporate law
        { :name => "Business and Corporate Law", :short_name => "Business Law", :name_de => "Wirtschafts- und Gesellschaftsrecht", :short_name_de => "Wirtschaftsrecht", :children => [
          { :name => "Corporate Law", :tags => "corporate law corporation company", :name_de => "Gesellschaftsrecht", :tags_de => "Körperschaftsrecht Gesellschaftsrecht Gesellschaft Firma Gründung Rechtsform Körperschaft" },
          { :name => "Maritime Law", :tags => "maritime law ships navy naval", :name_de => "Schifffahrtsrecht", :tags_de => "Schifffahrtsrecht Schifffahrt" },
          { :name => "Automobile Law", :tags => "automobile law auto car vehicle truck" },
          { :name => "Transport Law", :tags => "transportation transport law", :name_de => "Transport- und Speditionsrecht", :tags_de => "Frachtvertrag Speditionsvertrag Lagervertrag" },
          { :name => "Trade Law", :tags => "trade law", :name_de => "Handesgesetz", :tags_de => "Handelsgesetz Handel" },
          { :name => "Finance and Securities Law", :tags => "finance and sercurities law", :name_de => "Finanz- und Börsenrecht", :tags_de => "Finanzrecht Börsenrecht" },
          { :name => "Contract and Remedy Law", :tags => "contract remedy law", :name_de => "Vertragsrecht", :tags_de => "Vertragsrecht Vertrag Rechtsbehelf Nachbesserung Rechtsmittel Kaufvertrag" },
          { :name => "Banking Law", :tags => "banking bank law", :name_de => "Bankengesetz", :tags_de => "Bankengesetz Bank" },
          { :name => "Energy Law", :tags => "energy law gas oil electricity uranium plutonium" },
          { :name => "Entertainment Law", :tags => "entertainment law hollywood" },
          { :name => "Environmental Law", :tags => "environmental law environment pollution" },
          { :name_de => "Anwalts- und Gebührenrecht", :tags_de => "Anwalt Gebühren Gebührenrecht Anwaltsrecht Recht" },
          { :name => "Insurance Law", :tags => "insurance law", :name_de => "Versicherungsrecht", :tags_de => "Versicherungsrecht Versicherung versichern Recht" },
          { :name => "Health Care Law", :tags => "health care law", :name_de => "Krankenversicherungsgesetz", :tags_de => "Krankenversicherungsgesetz Krankenversicherung" },
          { :name_de => "Bau- und Architektenrecht", :tags => "Baurecht Architektenrecht Recht Bau Architektur Architekten Haus" },
          { :name => "Bankruptcy Law", :tags => "bankruptcy law bankrupt", :name_de => "Insolvenzrecht", :tags_de => "Insolvenzrecht Insolvenz insolvent Stundung Konkurs" },
          { :name_de => "Medizinrecht", :tags_de => "Medizinrecht Medizin Arzt Arznei Drogen Pharma Verschreibung verschreibungspflichtig Recht" },
          { :name_de => "Verwaltungsrecht",  :tags_de => "Verwaltungsrecht Verwaltung Recht" },
          { :name => "Investment Losses", :tags => "investment losses", :name_de => "Investitionsausfall", :tags_de => "Investitionsausfall" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" }
        ] },
        # antitrust
        { :name => "Antitrust and Competition Law", :short_name => "Antitrust Law", :name_de => "Wettbewerbs- und Urheberrecht", :short_name_de => "Kartellrecht", :children => [
          { :name => "Competition Law", :tags => "competition law competitive", :name_de => "Wettbewerbsrecht", :tags_de => "Wettbewerbsrecht Wettbewerb" },
          { :name => "Copyright Law", :tags => "copyright law", :name_de => "Urheberrecht", :tags_de => "Urheberrecht Urheber" },
          { :name => "Patent Law", :tags => "patent law", :name_de => "Patentrecht", :tags_de => "Patentrecht Patent Gebrauchsmusterrecht Gebrauchsmuster" },
          { :name => "Design Patent Law", :tags => "design patent law", :name_de => "Geschmacksmusterrecht", :tags_de => "Geschmacksmusterrecht Geschmacksmuster" },
          { :name => "Trademark Law", :tags => "trademark law", :name_de => "Markenrecht", :tags_de => "Markenrecht Marke" },
          { :name => "Intellectual Property Law", :tags => "intellectual property law IP copyright trademark patent", :name_de => "Geistiges Eigentum", :tags_de => "'Geistiges Eigentum' Urheberrecht Urheber Markenrecht Marken Marke Patent Patentrecht Copyright Immaterialgüterrecht" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" }
        ] },
        # employment law
        { :name => "Employment Law", :name_de => "Arbeitsrecht", :children => [
          { :name => "Labor Rights", :tags => "labor law employment employees employee", :name_de => "Arbeitnehmerrechte", :tags_de => "Arbeitnehmerrecht Arbeitsrecht Arbeitnehmer Arbeiter Angestellte Angestellter" },
          { :name => "Employment Law", :tags => "labor law employer employers", :name_de => "Arbeitgeberrecht", :tags_de => "Arbeitgeberrecht Arbeitsrecht Arbeitgeber Brötchengeber" },
          { :name => "Employment Discrimination Law", :tags => "employment discrimination", :name_de => "Diskriminierung von Arbeitnehmern", :tags_de => "Benachteiligung Anstellung Diskriminierung" },
          { :name => "Employment Contract", :tags => "employment contract", :name_de => "Arbeitsvertrag", :tags_de => "Arbeitsvertrag" },
          { :name => "Hostile Work Environment", :tags => "hostile environment sexual harassment", :name_de => "Feindseliges Arbeitsklima", :tags_de => "" },
          { :name => "Leave of Absence", :tags => "leave of absence", :name_de => "Beurlaubung", :tags_de => "Beurlaubung berulauben" },
          { :name => "Layoff", :tags => "layoff layoffs dismissal termination", :name_de => "Entlassung und Kündigung", :tags_de => "Entlassung Entlassungen betriebsbedingt betriebsbedingte Ausstellung Kündigung" },
          { :name => "Family and Medical Leave", :tags => "family medical leave" },
          { :name_de => "Kündigungsschutzrecht", :tags_de => "Kündigungsschutz Kündigungsschutzrecht" },
          { :name_de => "Mutterschutzrecht", :tags_de => "Mutterschutzrecht Mutterschutz" },
          { :name_de => "Befristete Arbeitsverhältnisse", :short_name_de => "Befristung", :tags_de => "befristete Arbeitsverhältnisse Befristung" },
          { :name_de => "Tarifvertragsrecht", :tags_de => "Tarifvertragsrecht Tarifvertrag" },
          { :name => "Disabilities Act", :tags => "disabilities disability", :name_de => "Behindertenschutzgesetz", :tags_de => "Behindertenschutzgesetz Behindertenschutz" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" }
        ] },
        # public law
        { :name => "Public Law", :name_de => "Öffentliches Recht", :children => [
          { :name => "Constitutional Law", :tags => "'civil right' law civil rights", :name_de => "Grund- und Bürgerrechte", :tags_de => "Bürgerrecht Bürgerrechte Grundrechte Grundrecht" },
          { :name => "Restaurant Law", :tags => "restaurants restaurant law", :name_de => "Gaststättenrecht", :tags_de => "Gaststättenrecht Gaststätte Restaurant Imbiss" },
          { :name => "Communications Law", :tags => "communications law communication internet telephone" },
          { :name => "Internet Law", :name_de => "Internetrecht", :tags => "internet law commerce eBay E-commerce auction auctions auctioned", :tags_de => "Internetrecht 'Internet-Recht' 'neue Medien' Internet E-Commerce eBay 'Online Auktion' Auktion auktionieren auktioniert eBay" },
          { :name => "Human Rights Law", :tags => "human rights law rights", :name_de => "Menschenrechte", :tags => "Menschenrechte Menschenrechts" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" }
        ] },
        # social security law
        { :name => "Government Benefits Law", :name_de => "Sozialrecht", :children => [
          { :name_de => "Pflegeversicherungsrecht", :tags_de => "Pflegeversicherungsrecht Pflegeversicherung" },
          { :name_de => "Rentenversicherungsrecht", :tags_de => "Rentenversicherungsrecht Rentenversicherung" },
          { :name_de => "Sozialhilferecht", :tags_de => "Sozialhilferecht Sozialhilfe" },
          { :name_de => "Schwerbehindertenrecht", :tags_de => "Schwerbehindertenrecht Schwerbehindert behindert" },
          { :name_de => "Wohngeldrecht", :tags_de => "Wohngeldrecht Wohngeld" },
          { :name_de => "Arbeitsförderungsgesetz", :tags_de => "Arbeitsförderungsgesetz Arbeitslosengeld Arbeitsamt" },
          { :name => "Disability Benefits Law", :short_name => "Disability Law", :tags => "disability benefits law", :name_de => " Invalidenrentengesetz", :tags_de => "Invalidenrentengesetz Invalide Rente" },
          { :name => "Unemployment Benefits Law", :tags => "unemployment benefit benefits", :name_de => "Arbeitslosenunterstützung", :tags_de => "Arbeitslosenunterstützung Arbeitslosengeld arbeitslos" },
          { :name => "Elder Law", :tags => "elder law" },
          { :name => "Health and Medicine Law", :short_name => "Health Law", :tags => "health medicine law", :name_de => "Krankenversicherungsrecht", :tags_de => "Krankenversicherungsrecht Krankenversicherung" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" }
        ] },
        # immigration
        { :name => "Immigration", :name_de => "Zuwanderung", :children => [
          { :name => "Citizenship and Residency", :tags => "citizenship residency", :name_de => "Staatsangehörigkeit", :tags_de => "Staatsangehörigkeit Einbürgerung" },
          { :name => "Deportation and Removal", :tags => "deportation removal", :name_de => "Ausweisung und Abschiebung", :tags_de => "Ausweisung Abschiebung" },
          { :name => "Green Cards", :tags => "green card" },
          { :name => "Work Visas", :tags => "work visas", :name_de => "Arbeitsvisa", :tags_de => "Arbeitsvisa Abeitsvisum Visum" },
          { :name_de => "Asylverfahren", :tags_de => "Asylverfahren Asyl" },
          { :name_de => "Aufenthaltserlaubnis", :tags_de => "Aufenthaltserlaubnis Visum" },
          { :name_de => "Arbeitserlaubnis", :tags_de => "Arbeitserlaubnis" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" }
        ] },
        # tax law
        { :name => "Tax Law", :name_de => "Steuerrecht", :children => [
          { :name => "Income Tax Law", :tags => "income tax law", :name_de => "Einkommensteuergesetz", :tags_de => "Einkommensteuergesetz Einkommensteuer" },
          { :name => "Corporation Tax Law", :tags => "corporation tax law", :name_de => "Körperschaftsteuergesetz", :tags_de => "Körperschaftsteuergesetz Körperschaft Firmen Steuer" },
          { :name => "Capital Transfer and Accessions Tax Law", :short_name => "Capital Transfer Tax Law", :tags => "capital transfer accession tax tax law", :name_de => "Erbschaft- und Schenkungsteuergesetz", :tags_de => "Erbschaftsteuergesetz Schenkungsteuergesetz" },
          { :name => "Business Tax Law", :tags => "business tax law", :name_de => "Gewerbesteuergesetz", :tags_de => "Gewerbesteuergesetz" },
          { :name_de => "Umsatzsteuergesetz", :tags_de => "Umsatzsteuergesetz Umsatzsteuer" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" }
        ] },
        # criminial law
        { :name => "Criminal Law", :name_de => "Strafrecht", :children => [
          { :name => "Personal Injury Law", :tags => "personal injury law assault battery mayhem bodily harm", :name_de => "Körperverletzung", :tags_de => "Körperverletzung Gewalt" },
          { :name => "Domestic Violance", :tags => "domestic violance", :name_de => "Häusliche Gewalt", :tags_de => "häuslich Gewalt 'Häusliche Gewalt'" },
          { :name => "Tax Evasion", :tags => "tax evation evations defraudation fiscal", :name_de => "Steuerflucht", :tags_de => "Steuerflucht Steuerhinterziehung" },
          { :name => "Drug Crimes", :tags => "drug crimes crime", :name_de => "Drogenverbrechen", :tags_de => "Drogenverbrechen Drogen Verbrechen" },
          { :name => "Drunk Driving", :tags => "drunk driving DUI", :name_de => "Autofahren unter Alkoholeinfluss", :tags_de => "Autofahren Alkoholeinfluss" },
          { :name => "Traffic Violations", :tags => "traffic violations", :name_de => "Verletzung der Straßenverkehrsordnung", :tags_de => "Verletzung Straßenverkehrsordnung" },
          { :name => "Breach of Domestic Peace", :tags => "trespas 'breach of domestic peace' 'unlawful entry'", :name_de => "Hausfriedensbruch", :tags_de => "Hausfriendsbruch" },
          { :name => "Hit and Run Offence", :tags => "", :name_de => "Unerlaubtes Entfernen vom Unfallort", :tags_de => "Fahrerflucht" },
          { :name => "Perjury", :tags => "false testimony perjury", :name_de => "Meineid", :tags_de => "Falschaussage Meineid falsche eidliche Aussage" },
          { :name => "Defamation and Libel", :tags => "defamation law backbiting asperse libel detraction slander", :name_de => "Beleidigung und Verleumdung", :tags_de => "Beleidigung beleidigen Verleumdung verleumden" },
          { :name => "Kidnapping", :tags => "kidnapping kidnap hostage hostages", :name_de => "Entführung", :tags_de => "Entführung Menschenraub Kidnapping Kinderhandel Verschleppung Geiselnahme" },
          { :name => "Coercion", :tags => "coercion", :name_de => "Nötigung", :tags_de => "Nötigung sexuell sexuelle" },
          { :name => "Burglary", :tags => "burglary larceny theft thievery", :name_de => "Diebstahl", :tags_de => "Diebstahl stehlen" },
          { :name => "Defalcation", :tags => "defalcation concealment embezzlement fraud", :name_de => "Unterschlagung", :tags_de => "Unterschlagung verbergen unterschlagen Verheimlichung verschweigen" },
          { :name => "Deprivation", :tags => "deprivation heist predation rape robbery swag", :name_de => "Raub", :tags_de => "Raub rauben Raubüberfall" },
          { :name => "Blackmail", :tags => "blackmail extortion", :name_de => "Erpressung", :tags_de => "Erpressung" },
          { :name => "Forging", :tags => "forging falsification forgery money counterfeiting counterfeit", :name_de => "Urkundenfälschung", :tags_de => "Fälschung Geldfälschung" },
          { :name => "Insolvency Fraud", :tags => "insolvency fraud", :name_de => "Insolvenzstraftaten", :tags_de => "Insolvenzstraftaten" },
          { :name => "Arson", :tags => "malicious arson 'fire raising' incendiarism", :name_de => "Brandstiftung", :tags_de => "Brandstiftung Brandgefahr" },
          { :name => "Environmental Offenses", :tags => "environmental environment offense felony pollution", :name_de => "Umweltstraftaten", :tags_de => "Umweltstraftaten Umweltstraftat Umweltverschmutzung" },
          { :name => "Corruption", :tags => "corruption corruptibility venality", :name_de => "Bestechlichkeit", :tags_de => "Bestechlichkeit Bestechung Korruption" },
          { :name => "Vandalism", :tags => "vandalism 'property damage' graffity", :name_de => "Vandalismus", :tags_de => "Vandalismus Wandalismus böswillige Beschädigung" },
          { :name => "Sexual Assault, Rape", :tags => "sexual assault rape", :name_de => "Sexuelle Nötigung, Vergewaltigung", :tags_de => "'Sexuelle Nötigung' Vergewaltigung 'Sexueller Übergriff'" },
          { :name => "Child Abuse", :tags => "child abuse", :name_de => "Kindesmisshandlung", :tags_de => "Kindesmisshandlung Kindesmissbrauch Missbrauch Misshandlung" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" }
        ] },
      ] },
      # Finance & Accounting
      { :name => "Finance and Accounting", :short_name => "Finance", :name_de => "Finanzen und Buchhaltung", :short_name_de => "Finanzen", :children => [
        { :name => "Accounting and Taxes", :short_name => "Accounting", :name_de => "Buchführung und Steuern", :short_name_de => "Buchführung", :children => [
          # Accounting & Taxes - mixed
          { :name => "Deprecations and Amortizations", :tags => "deprecate depreciate amortize", :name_de => "Abschreibungen", :tags_de => "Abschreibung Abschreibungen abschreiben" },
          { :name => "Retirement Provision", :tags => "retirement provision", :name_de => "Altersvorsorge und Pension", :tags_de => "Altersvorsorge Pension Altersvorsorge" },
          { :name => "Accounting", :tags => "accounting practices GAAP", :name_de => "Buchhaltung", :tags_de => "Buchführung Rechnungswesen buchführen Kontenführung Buchhaltung GAAP" },
          { :name => "Import Tax", :tags => "import tax customs", :name_de => "Zölle", :tags_de => "Einfuhr Wareneinfuhr Ware Steuer Zoll" },
          { :name => "Expenses", :tags => "expenses expense report tax", :name_de => "Werbungskosten", :tags_de => "Spesen Werbungskosten Steuern" },
          { :name => "Corporate Tax", :tags => "corporate tax corporation", :name_de => "Unternehmenssteuern", :tags_de => "Unternehmenssteuern Unternehmenssteuer Unternehmen Steuern" },
          { :name => "Tax Liability", :tags => "tax liability liabilities dependencies", :name_de => "Steuerpflicht", :tags_de => "Steuerpflicht Steuer" },
          { :name => "Tax Return", :tags => "'tax return'", :name_de => "Steuererklärung", :tags_de => "Steuererklärung Einkommenssteuer Erklärung Steuer" },
          { :name => "Freelance", :tags => "freelance employment self-employment entrepreneur entrepreneurship", :name_de => "Freiberufler", :tags_de => "Freiberufler freiberuflich Gewerbe Unternehmer" },
          { :name => "Salaries and Wages", :tags => "salaries salary wages wage pay-check earnings", :name_de => "Löhne und Gehälter", :tags_de => "Löhne Lohn Gehalt Gehälter Einkommen Lohnabrechnung" },
          { :name => "Corporation", :tags => "corporate corporation", :name_de => "Kapitalgesellschaft", :tags_de => "Kapitalgesellschaft Gesellschaft 'Gesellschaft mit beschränkter Haftung' GmbH Aktiengesellschaft AG" },
          { :name => "Internal Revenue", :tags => "IRS 'Internal Revenue Service'", :name_de => "Finanzamt", :tags_de => "Finanzamt" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" },
          # Accounting & Taxes - English US only
          { :name => "Capital Transfer", :tags => "capital transfer" },
          { :name => "Real Estate", :tags => "'real estate' real estate property" },
          { :name => "Equity", :tags => "company assets equity" },
          { :name => "Capital Gains", :tags => "capital gains" },
          { :name => "Consumer Taxes", :tags => "consumer taxes VAT" },
          { :name => "Sales Tax", :tags => "VAT sales tax consumer" },
          # Accounting & Taxes - German only
          { :name_de => "Außergewöhnliche Belastungen", :tags_de => "'Außergewöhnliche Belastungen' aussergewöhnliche Belastungen" },
          { :name_de => "Einkommenssteuer", :tags_de => "Einkommenssteuer Einkommenssteuererstattung" },
          { :name_de => "Erbschaftssteuer", :tags_de => "Erbschaftssteuer Erbschaft Erbe Schenkung" },
          { :name_de => "Haus- und Grundbesitz", :tags_de => "Hausbesitz Grundbesitz Immobilien" },
          { :name_de => "Kapitalvermögen", :tags_de => "Kapitalvermögen Einnahmen Kapitaleinnahmen Kapitalvermögen" },
          { :name_de => "Kindergeld", :tags_de => "Kindergeld Kind Kinder" },
          { :name_de => "Elterngeld", :tags_de => "Elterngeld Erziehung" },
          { :name_de => "Mehrwertsteuer", :tags_de => "Mehrwertsteuer Umsatzsteuer" },
          { :name_de => "Renten und Pensionen", :tags_de => "Renten Pensionen Rente Pension Altersvorsorge" },
          { :name_de => "Schenkungssteuer", :tags_de => "Schenkungssteuer" },
          { :name_de => "Sonderausgaben", :tags_de => "Sonderausgaben" },
          { :name_de => "Umsatzsteuer", :tags_de => "Umsatzsteuer Mehrwertsteuer Vorsteuer" },
        ] },
        #+  
        { :name => "Real Estate", :name_de => "Immobilien", :children => [
          { :name => "Home", :tags => "home homes house houses property", :name_de => "Eigenheim", :tags_de => "Eigenheim Eigenheime Haus Eigentum" },
          { :name => "Land", :tags => "land landowner estate landholding property", :name_de => "Grundstück", :tags_de => "Grundstück Grundstücke Grundbesitz Ländereien Terrain" },
          { :name => "Commercial", :tags => "commercial", :name_de => "Gewerblich", :tags_de => "gewerblich Gewerberfläche" },
          { :name => "Condos", :tags => "condo condominium condominiums", :name_de => "Eigentumswohnungen", :tags_de => "Eigentumswohnung Wohnung" },
          { :name => "Residential", :tags => "residential", :name_de => "Wohngebäude", :tags_de => "Wohngebäude Siedlung Wohnhaus" },
          { :name => "Buying Properties", :tags => "real estate property buying", :name_de => "Immobilienkauf", :tags_de => "Immobilienkauf Kauf" },
          { :name => "Selling Properties", :tags => "real estate property selling", :name_de => "Immobilienverkauf", :tags_de => "Immobilienverkauf Verkauf" },
          { :name => "Renting and Leasing", :tags => "renting leasing rent lease temporary rentals", :name_de => "Vermietung und Verpachtung", :tags_de => "Vermietung Verpachtung temporäre Miete Pacht" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" },
        ] },
        { :name => "Financing", :name_de => "Finanzierung", :children => [
          { :name => "Foreign Investment", :tags => "foreign investment", :name_de => "Fremdfinanzierung", :tags_de => "Fremdfinanzierung" },
          { :name => "Public Funding", :tags => "public funding", :name_de => "Finanzierung aus Öffentlichen Mitteln", :tags_de => "Finazierung öffentlich öffentlichen" },
          { :name => "IPO", :tags => "ipo 'initial public offering' 'public offering' shares share", :name_de => "Börsengang", :tags_de => "Börsengang Emittierung Börse" },
          { :name => "Venture Capital", :tags => "risk venture capital entrepreneur entrepreneurship", :name_de => "Risikokapital", :tags_de => "Risikokapital Risiko Kapital Unternehmer Unternehmen" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" },
        ] },
        { :name => "Economics", :tags => "economics inflation currency", :name_de => "Volkswirtschaft", :tags_de => "Volkswirtschaft Inflation Währung" },
        { :name => "Mergers and Acquisitions", :tags => "mergers acquisitions acquisition M&A M&As", :name_de => "Fusionen und Firmenübernahmen", :tags_de => "Fusionen Firmenfusionen Firmenfusion Firmenübernahme Übernahme" },
        { :name => "Risk Management", :tags => "risk management damage", :name_de => "Risikomanagement", :tags_de => "Risikomanagement Risiko Schaden" },
        { :name => "Miscellaneous", :name_de => "Generelle Themen" }
        #-
      ] },
      # Companies / Organizations
      { :name => "Companies and Organizations", :short_name => "Organizations", :name_de => "Firmen und Institutionen", :short_name_de => "Institutionen", :children => [
        { :name => "Employer", :tags => "employer entrepreneur", :name_de => "Arbeitgeber", :tags_de => "Arbeitgeber Unternehmer" },
        { :name => "Employment", :tags => "employment job", :name_de => "Arbeitsverhältnis", :tags_de => "Arbeitsverhältnis Anstellung Arbeit Job" },
        { :name => "Work Conditions", :tags => "work conditions 'working atmosphere' morale", :name_de => "Arbeitsbedinungen", :tags_de => "Arbeitsbedinungen Arbeitsmoral Moral" },
        { :name => "Work Culture and Ethics", :tags => "work culture ethics coprorate culture", :name_de => "Firmenkultur und -ethik", :tags_de => "Firmenkultur Firmenethik Betriebsklima" },
        { :name => "Advertising", :tags => "advertising advertise commercial commercials", :name_de => "Werbung und Reklame", :tags_de => "Werbung Reklame" },
        { :name => "Discrimination", :tags => "discrimination 'affirmative actions' reverse sexual action apartheid", :name_de => "Diskriminierung", :tags => "sexuell sexuelle Diskriminierung rassistisch" },
        { :name => "Marketing and PR", :tags => "marketing 'public relations' PR pricing price distribution", :name_de => "Marketing und Presse", :tags_de => "Marketing Press Öffentlichkeitsarbeit Marketing Presse Preis Preise Vertrieb Vertriebswege Vertriebsweg" },
        { :name => "Harassment", :tags => "bullying workplace", :name_de => "Mobbing", :tags_de => "Mobbing Schikane Terror" },
        { :name => "Freelance and Contracting", :short_name => "Contracting", :tags => "freelance contracting consulting consultant", :name_de => "Freiberufliche und Kontraktoren", :short_name_de => "Freiberufler", :tags_de => "freiberuflich Freiberufler Kontraktor Gewerbe gewerblich" },
        { :name => "Job Search", :tags => "job search jobs employment", :name_de => "Arbeitssuche", :tags_de => "Arbeitssuche Job Anstellung" },
        { :name => "Certificates and Licenses", :short_name => "Certificates", :tags => "certificates certificate certification licenses certification license", :name_de => "Zertifikate und Lizenzen", :short_name_de => "Zertifikate", :tags_de => "Zertifikate Zeugnis Lizenzen Genehmigung Genehmigungen Lizenz zertifizieren" },
        { :name => "Occupational Training", :short_name => "Training", :tags => "occupation occupational training education", :name_de => "Ausbildung", :tags_de => "Ausbildung berufliche Lehre Beruf" },
        { :name => "Labor Unions", :tags => "labor union unions collective wage agreement", :name_de => "Gewerkschaften", :tags_de => "Gewerkschaften Gewerkschaft Tarifvertrag Flächentarif Flächentarifvertrag" },
        { :name => "Mentoring", :tags => "mentoring mentor counceling", :name_de => "Betreuung", :tags_de => "Betreuung Mentor beraten Berater" },
        { :name => "Networking", :tags => "professional networking", :name_de => "Netzwerken", :tags_de => "Netzwerken professionell professionelles Netzwerk" },
        { :name => "Customer Service", :short_name => "Service", :tags => "customer service", :name_de => "Kundendienst", :tags_de => "Kundendienst Service" },
        { :name => "Sales and Distribution", :short_name => "Sales", :tags => "sales distribution", :name_de => "Verkauf und Vertrieb", :short_name_de => "Vertrieb", :tags_de => "Verkauf Vertrieb" },
        { :name => "Partnerships and Joint Ventures", :short_name => "Partnerships", :tags => "partner partnering partnerships partnership joint venture", :name_de => "Partnerschaften und Joint Ventures", :short_name_de => "Partnerschaften", :tags_de => "Partnerschaft 'Joint Venture' Arbeitsgemeinschaft Beteiligungsunternehmen Interessengemeinschaft Gemeinschaftsunternehmen" },
        { :name => "Investment", :tags => "investment investments investor investors", :name_de => "Investment", :tags_de => "Investment Investierung" },
        { :name => "Subsidiaries", :tags => "subsidiary plant", :name_de => "Niederlassungen", :tags_de => "Niederlassung Zweigniederlassung Betriebsteil Firmenniederlassung Niederlassungen" },
        { :name => "Management Team", :short_name => "Management", :tags => "management team executives CEO COO CFO", :name_de => "Geschäftsführung", :tags_de => "Geschäftsführung Geschäftsführer Management CEO" },
        { :name => "Technical Support", :tags => "'technical support' technical support hotline", :name_de => "Technischer Kundendienst", :tags_de => "'Technischer Kundendienst' technischer technisch Kundendienst Support" },
        { :name => "Miscellaneous", :name_de => "Generelle Themen" },
        { :name => "Products and Services", :short_name => "Products", :name_de => "Produkte und Dienstleistungen", :short_name_de => "Produkte", :children => [
          { :name => "Design", :tags => "design", :name_de => "Design", :tags_de => "Design" },
          { :name => "General Questions", :short_name => "Questions", :tags => "question questions answer answers solution solutions case cases", :name_de => "Allgemeine Fragen", :short_name_de => "Fragen", :tags_de => "Frage Fragen Antwort Antworten Fall Fälle" },
          { :name => "Problems", :tags => "problem issue issues case", :name_de => "Probleme", :tags_de => "Problem Fall Probleme Fälle" },
          { :name => "Pricing", :tags => "price pricing", :name_de => "Preis", :tags_de => "Preis Preise Preisvergabe Preisangebot" },
          { :name => "Distribution", :tags => "distribution selling channel", :name_de => "Vertrieb", :tags_de => "Verkaufskanal Vertrieb verkaufen Verkauf" },
          { :name => "Product Ideas", :tags => "product idea ideas suggestions suggestion improvment", :name_de => "Produktideen", :tags_de => "Ideen Idee Produktideen Verbesserungsvorschläge Verbesserungsvorschlag" },
          { :name => "Quality and Defects", :tags => "quality defects bugs bug", :name_de => "Qualität und Mängel", :tags_de => "Qualität Mängel Defekt Fehler Programmfehler" },
          { :name => "Customer Service", :tags => "customer service", :name_de => "Kundendienst", :tags_de => "kundendienst service" },
          { :name => "Technical Support", :tags => "technical support service", :name_de => "Technischer Kundendienst", :tags_de => "technisch technischer Kundendienst Support" },
          { :name => "Advertising and Marketing", :tags => "advertising marketing commercial", :name_de => "Werbung und Marketing", :tags_de => "Werbung Marketing Anzeigen Anzeige" },
          { :name => "Sales", :tags => "sales sell 'point of sales'", :name_de => "Vertrieb", :tags_de => "Verkauf Vertrieb Vertriebsstandort" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" },
        ] },
      ] },
      # Health
      { :name => "Health", :name_de => "Gesundheit", :children => [
        { :name => "Alternative Medicine", :tags => "homeopathy alternative medicine", :name_de => "Alternativmedizin", :tags_de => "alternative Medizin Homöopathie" },
        { :name => "Beauty", :tags => "beauty parlour", :name_de => "Schönheit", :tags_de => "Schönheit plastische Chirurgie 'Plastische Chirurgie' Kosmetik" },
        { :name => "Children's Health", :short_name => "Children", :tags => "child children health", :name_de => "Kindermedizin", :tags_de => "Kindermedizin Kinder Kind" },
        { :name => "Death and Dying", :tags => "death dying cemetry euthanasia suicide", :name_de => "Tot und Sterben", :tags_de => "Tot Sterben Suizid Euthanasie" },
        { :name => "Dental Health", :tags => "dentist dental health teeth tooth", :name_de => "Zähne", :tags_de => "Zähne Zahn Zahnartzt" },
        { :name => "Disabilities", :tags => "disability disabilities invalidity unemployability", :name_de => "Behinderungen", :tags_de => "Arbeitsunfähigkeit Behinderung Behinderungen Berufsunfähigkeit Invalidität" },
        { :name => "Emergency and First Aid", :tags => "emergency ambulance 'first aid'", :name_de => "Notfälle und Erste Hilfe", :tags_de => "Nothilfe 'Erste Hilfe' Notzustand Ambulanz Krankenwagen" },
        { :name => "Health Care", :tags => "healthcare 'health care'", :name_de => "Gesundheitspflege", :tags_de => "Gesundheitspflege Gesundheit Pflege" },
        { :name => "Hospitals and Medical Centers", :tags => "hospitals medical center", :name_de => "Krankenhäuser", :tags_de => "Krankenhäuser Krankenhaus Therapiezentrum Therapiezentren" },
        { :name => "Hygiene", :tags => "hygiene sanitation", :name_de => "Gesundheitspflege", :tags_de => "Gesundheitspflege Hygiene Körperpflege" },
        { :name => "Mental Health", :tags => "psychology psychological mental health", :name_de => "Psychische Verfassung", :tags_de => "psychisch psychische Verfassung Psychologie psychologisch" },
        { :name => "Midwifery", :tags => "obstetric midwifery midwife birth", :name_de => "Geburtshilfe", :tags_de => "Geburt Neugeboren Neugeborene Geburtshelfer Geburtshilfe Hebamme Entbindung" },
        { :name => "Nursing", :tags => "nursing", :name_de => "Stillen", :tags_de => "Stillen" },
        { :name => "Pharmacy", :tags => "pharmacy drug drugs medicine persribe prescription", :name_de => "Apotheke", :tags_de => "Apotheke Arznei Verschreiben Medikament Rezept" },
        { :name => "Sexual Health", :tags => "sex sexual health", :name_de => "Sexualgesundheit", :tags_de => "Sexualgesundheit Sex sexuell" },
        { :name => "Weight Issues", :tags => "weight obesity", :name_de => "Gewichtsproblemeprobleme", :tags_de => "Gewichtsproblemeprobleme Fettleibigkeit Fettsucht fettsüchtig" },
        { :name => "Medicine", :name_de => "Medizin", :children => [
          { :name => "Oncology", :tags => "tumor tumors cancer ocology chemotherapy radiotherapy", :name_de => "Onkologie", :tags_de => "Onkology Krebs Tumor Tumore Chemotherapie" },
          { :name => "Audiology", :tags => "audiology hearing 'hearing aid'", :name_de => "Audiologie", :tags_de => "Audiologie Hörgeräte Hörgerät Hörschaden" },
          { :name => "Cardiology", :tags => "heart blood vessels vessel 'heart condition'", :name_de => "Kardiologie", :tags_de => "Kardiologie Herz herzkrank Herzkrankheit Herzkrankheiten" },
          { :name => "Chiropractic", :tags => "healthcare spine joint spines joints", :name_de => "Therapeutische Verfahren", :tags_de => "therapeutische Verfahren Chiropraktik Chiropraktisch Chiropraktiker Therapeut Rücken Gelenk" },
          { :name => "Clinical Trials", :tags => "'clinical trial' 'clinical trials' clinical trials", :name_de => "Klinische Versuche", :tags_de => "Klinische Versuche Probanden Probant klinisch 'Klinische Versuche'" },
          { :name => "Cosmetic and Plastic Surgery", :tags => "cosmetic plastic surgery", :name_de => "Plastische Chirurgie", :tags_de => "Plastische Chirurgie" },
          { :name => "Dentistry", :tags => "dentist dentistry tooth teeth", :name_de => "Zahnmedizin", :tags_de => "Zahnmedizin Zähne Zahn Zahnarzt" },
          { :name => "Dermatology", :tags => "dermatology skin 'skin disease' 'skin diseases'", :name_de => "Dermatologie", :tags_de => "Dermatologie Haut Hauterkrankung Dermatologie dermatologisch" },
          { :name => "Emergency Medicine", :tags => "emergency 'emergency medicine' 'first aid'", :name_de => "Notfallmedizin", :tags_de => "Notfallmedizin Notfall Medizin 'Erste Hilfe'" },
          { :name => "Epidemiology", :tags => "epidemiology infection infectious 'infectious disease'", :name_de => "Epidemiologie", :tags_de => "Epidemiologie ansteckend ansteckende Krankheit Ansteckung ansteckende Ansteckungsgefahr" },
          { :name => "Family Medicine", :tags => "family 'family medicine' 'general practitioner' primary care GP", :name_de => "Familienmedizin", :tags_de => "Familienmedizin Familienarzt Hausarzt Allgemeinmedizin Allgemeinarzt" },
          { :name => "Gastroenterology", :tags => "gastroenterology digestion digestive 'digestive system' etymologically etymology", :name_de => "Gastroenterologie", :tags_de => "Gastroenterologie Verdauung Verdauungsstörung Verdauungssystem" },
          { :name => "Hematology", :tags => "hematology blood blood-forming 'blood disease' 'blood cell' 'blood cells'", :name_de => "Hämatologie", :tags_de => "Hämatologie Blut 'Blut produzierend'" },
          { :name => "Immunology", :tags => "immunology 'immune system'", :name_de => "Immunologie", :tags_de => "Immunologie Immunsystem Immun-system" },
          { :name => "Infectious Diseases", :tags => "infectious 'infectious disease' immunology", :name_de => "Ansteckungskrankheiten", :tags_de => "Ansteckungskrankheiten Ansteckungskrankheit Ansteckungsgefahr" },
          { :name => "Informatics", :tags => "'medical informatics' informatics", :name_de => "Medizinische Informatik", :tags_de => "Informatik 'Medizinische Informatik'" },
          { :name => "Kinesiology", :tags => "kinesiology 'human movement' movement", :name_de => "Kinesiologie", :tags_de => "Kinesiologie Bewegung Bewegungsapparat Bewegungsablauf bewegen" },
          { :name => "Neurology", :tags => "neurology 'nervous system' nervous neurologists", :name_de => "Neurologie", :tags_de => "Neurologie Nervensystem Neurologe Nervenarzt" },
          { :name => "Gynecology", :tags => "gynecology obstetrics menstruation gynecologist", :name_de => "Gynäkologie", :tags_de => "Gynäkologie Menstruation menstruieren Gynäkologe" },
          { :name => "Occupational Therapy", :tags => "'occupational therapy' therapy", :name_de => "Beschäftigungstherapie", :tags_de => "Beschäftigungstherapie Ergotherapie Arbeitstherapie" },
          { :name => "Ophthalmology", :tags => "optometry ophthalmology eyes eye 'eye specialist' oculist ophthalmologist", :name_de => "Augenheilkunde", :tags_de => "Optometrie Augenarzt Augenheilkunde Augen Auge sehen Sehschwäche" },
          { :name => "Orthopedics", :tags => "orthopedics muscle skeleton", :name_de => "Orthopädie", :tags_de => "Orthopädie Muskel Museln Skelett" },
          { :name => "Osteopathy", :tags => "osteopathy therapeutic", :name_de => "Osteopathie", :tags_de => "Osteopathie therapeutisch" },
          { :name => "Otolaryngology", :tags => "otolaryngology ear otorhinolaryngology nose throat", :name_de => "Hals-Nasen-Ohrenheilkunde", :tags_de => "Hals-Nasen-Ohrenheilkunde Hals-Nasen-Ohren-Arzt 'HNO Arzt' HNO-Arzt HNO" },
          { :name => "Palliative Care", :tags => "'palliative care' therapy curative cure", :name_de => "Heilbehandlung", :tags_de => "Heilbehandlung Kur Therapie" },
          { :name => "Pathology", :tags => "pathology tissue tissues cells cell organ organs", :name_de => "Pathologie", :tags_de => "Pathologie Zellen Zelle Gewebe Organ Organe" },
          { :name => "Pediatrics", :tags => "pediatrics pediatrician pediatrist pediatrists baby child children", :name_de => "Kinderheilkunde", :tags_de => "Kinderheilkunde Pädiatrie Kinderarzt Kinderärztin Kinderärzte" },
          { :name => "Physical Therapy", :tags => "'physical therapy' physiotherapy physical movement healthcare", :name_de => "Physiotherapie", :tags_de => "Physiotherapie Bewegung bewegen" },
          { :name => "Physician Assistant", :tags => "physician assistant PA", :name_de => "Arzthelfer", :tags_de => "Arzthelfer" },
          { :name => "Physiology", :tags => "mechanical mechanics mechanic physical biochemical biochemistry organism organisms", :name_de => "Physiologie", :tags_de => "Physiologie Mechanik mechanisch physikalisch Physik Organismus" },
          { :name => "Podiatry", :tags => "podiatry foot ankle knee leg hip", :name_de => "Podologie", :tags_de => "Podologie Fußorthopädie 'medizinische Fußpflege' Fußpflege" },
          { :name => "Psychiatry ", :tags => "psychiatry mental disorder disorders crazy", :name_de => "Psychiatrie", :tags_de => "Psychiatrie Verwirrung Fehlsteuerung mental geistig geistige Seele seelisch übergeschnappt überschnappen" },
          { :name => "Radiology ", :tags => "X-ray medical imaging diagnostic imaging radiography", :name_de => "Radiologie", :tags_de => "Radiologie Radiografie Röntgenologie Strahlenforschung Röntgenforschung Strahlentherapie" },
          { :name => "Sleep Medicine", :tags => "sleep medicine 'sleep medicine'", :name_de => "Schlafmedizin", :tags_de => "Schlafmedizin Schlaf Medizin" },
          { :name => "Sports Medicine", :tags => "'sports medicine' sports sport medicine", :name_de => "Sportmedizin", :tags_de => "Sportmedizin Sport sport" },
          { :name => "Surgery", :tags => "Surgery", :name_de => "Arztpraxis", :tags_de => "Arztpraxis Behandlungsraum Sprechstunde Chirurgie" },
          { :name => "Toxicology", :tags => "toxicology adverse 'adverse effects' chemicals", :name_de => "Toxikologie", :tags_de => "Toxikologie Beeinträchtigung chemisch Chemikalien " },
          { :name => "Urology", :tags => "urology urinary 'urinary tracts' reproductive urinate", :name_de => "Urologie", :tags_de => "Urologie Harn Urin Reproduktion Harnwege urinieren" },
          { :name => "Vascular Medicine", :tags => "'vascular medicine' vessel vessels vein veins lymphatic", :name_de => "Gefäßmedizin", :tags_de => "Gefäßmedizin Gefäß Gefäße" },
          { :name => "Intestine", :tags => "intestine bowel gut gastrointestinal abdomen", :name_de => "Darm", :tags_de => "darm eingeweide gedärm innereien stuhlgang reizdarm abdomen" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" }
        ] },
        { :name => "Diseases and Conditions", :name_de => "Krankheit und Verfassung", :children => [
          { :name => "Allergies", :tags => "allergies allergy", :name_de => "Allergien", :tags_de => "Allergien" },
          { :name => "Anxiety Disorders", :tags => "'anxiety disorder' 'anxiety disorders' anxiety disorder trepidation", :name_de => "Angststörungen", :tags_de => "Angststörungen Angststörung Angst Beklemmung" },
          { :name => "Autoimmune Diseases", :tags => "'autoimmune disease' 'immune system' diabetes 'multiple sclerosis'", :name_de => "Autoimmunkrankheiten", :tags_de => "Autoimmunkrankheiten Autoimmunkrankheit Immunsystem Diabetes 'Multiple Sclerosis'" },
          { :name => "Back and Neck Injuries", :tags => "back neck injuries", :name_de => "Rücken- und Nackenverletzungen", :tags_de => "Rückenverletzungen Rückenverletzung Rücken Nackenverletzungen Nackenverletzung Nacken" },
          { :name => "Birth Defects", :tags => "'birth defect' 'birth defects' birth-defect birth", :name_de => "Geburtsschäden", :tags_de => "Geburtsschäden Geburtsfehler Geburtsschaden Geburtsdefekt" },
          { :name => "Cancer", :tags => "cancer cancers", :name_de => "Krebs", :tags_de => "Krebs Krebsgeschwür" },
          { :name => "Dental Conditions", :tags => "'dental condition' 'dental conditions' dental dentist teeth tooth jaw denture", :name_de => "Zahnschmerzen", :tags_de => "Zahnschmerzen Zahnschmerz Zahnarzt Zähne Zahn Schmerzen Gebiss Kiefer" },
          { :name => "Depressive Disorders", :tags => "depression depressive 'depressive disorder' doldrums", :name_de => "Depressionen", :tags_de => "Depressionen Depression Niedergeschlagenheit" },
          { :name => "Digestion and Nutrition Disorders", :tags => "digestion digest nutrition nutritions", :name_de => "Verdauungs- und Ernährungsstörungen", :tags_de => "Verdauung Verdauungsstörung Verdauungsstörungen Ernährung Ernährungsstörungen Ernährungsstörung" },
          { :name => "Eating Disorders", :tags => "'eating disorder' 'eating disorder' eating disorder anorexia anorexic bulimia bulimic", :name_de => "Essstörungen", :tags_de => "Essstörung Essstörungen Bulimie Fresssucht Fress-Brechsucht Magersucht Appetitlosigkeit Anorexie" },
          { :name => "Eye Conditions", :tags => "'eye condition' 'eye conditions' eye conditions myopic short-sighted hyperopic long-sighted farsighted", :name_de => "Sehstörungen", :tags_de => "Sehstörung Sehstörungen kurzsichtig weitsichtig myopisch Myopia hyperopisch" },
          { :name => "Gastrointestinal Diseases", :tags => "gastrointestinal diseases intestine digestive digestion vomit diarea", :name_de => "Magen- und Darmstörungen", :tags_de => "Darmstörungen Magenschmerzen Magenstörungen Magenstörung Durchfall Erbrechen" },
          { :name => "Genetic Disorders", :tags => "'genetic disorder' genes gene genetic chromosomes chromosome chromosomal hereditary", :name_de => "Erbkrankheiten", :tags_de => "Erbkrankheit Erbkrankheiten Chromosomen Chromosom" },
          { :name => "Heart Diseases", :tags => "'heart diseases' 'heart disease' heart", :name_de => "Herzerkrankungen", :tags_de => "Herzerkrankung Herzerkrankungen Herz" },
          { :name => "Infectious Diseases", :tags => "'infectious disease' 'infectious diseases' bacteria virus fungi fungus protozoa prions prion contagious infectious flu", :name_de => "Infektionskrankheiten", :tags_de => "'Infektionskrankheiten' 'Infektionskrankheit' Infektion Bakterium Bakterien Virus Viren Fungus Fungi ansteckend Grippe grippal" },
          { :name => "Insect Bites and Stings", :tags => "'insect bites' 'insect bite' 'insect stings' 'insect sting' insect bites stings", :name_de => "Insektenstiche und -bisse", :tags_de => "Insekt Insektenstich Insektenstichwunde Stachel Insektenbiss" },
          { :name => "Kidney Diseases", :tags => "kidney 'kidney diseases' 'kidney disease'", :name_de => "Nierenerkrankung", :tags_de => "Nierenerkrankung Nierenstörung Nierenleiden Nierenstörungen Nierenfunktion Niere Nieren" },
          { :name => "Liver Diseases", :tags => "'liver disease' 'liver diseases' liver", :name_de => "Leberleiden", :tags_de => "Leberleiden Leber" },
          { :name => "Mental Health Disorders", :tags => "mental health disorders psychology psychological", :name_de => "Psychische Störungen", :tags_de => "psychische Störungen psychisch psychologisch" },
          { :name => "Pregnancy Complications", :tags => "pregnancy complications 'pregnancy complications' pregnancy pregnant", :name_de => "Schwangerschaftsstörungen", :tags_de => "Schwangerschaftsstörungen Schwangerschaftsstörung schwanger Schwangerschaft" },
          { :name => "Respiratory Diseases", :tags => "respiratory 'respiratory system' 'respiratory diseases' 'respiratory disease' breath breathing", :name_de => "Atemwegserkrankungen", :tags_de => "Atemwegserkrankung Atemwegserkrankungen Atemwege Atemnot Atemprobleme" },
          { :name => "Sexually Transmitted Diseases (STDs)", :tags => "'Sexually Transmitted Diseases' STD STDs sex sexual 'sexual intercourse' sexually transmitted", :name_de => "Geschlechtskrankheiten", :tags_de => "Geschlechtskrankheiten Geschlechtskrankheit Sex sexuell übertragbar übertragen Geschlechtsverkehr STD" },
          { :name => "Skin Conditions", :tags => "'skind condition' 'skin conditions' acne", :name_de => "Hauterkrankungen", :tags_de => "Hauterkrankungen Hauterkrankung Akne Haut" },
          { :name => "Sleep Disorders", :tags => "sleep disorders 'sleep disorder' somnipathy sleep", :name_de => "Schlafstörungen", :tags_de => "Somnipathie Schlaf schlafen Schlafstörung Schlafstörungen" },
          { :name => "Stomach Diseases", :tags => "stomach abscess blain ulcer", :name_de => "Magenerkrankungen", :tags_de => "Magenerkrankungen Magenerkrankung Magen Geschwür Magengeschwür" },
          { :name => "Thyroid Diseases", :tags => "thyroid", :name_de => "Schilddrüsenkrankheiten", :tags_de => "Schilddrüse" },
          { :name => "Tropical Diseases", :tags => "infectious tropical subtropical mosquito", :name_de => "Tropenkrankheiten", :tags_de => "tropisch Tropenkrank Tropenkrankheit Tropenkrankheiten" },
        ] },
        { :name => "Food and Nutrition", :tags => "food nutrition", :name_de => "Lebensmittel und Ernährung", :tags_de => "Lebensmittel Ernährung" },
        { :name => "Fitness", :tags => "fitness wellness", :name_de => "Fitness", :tags_de => "fitness wellness" },
        { :name => "Psychology and Mind", :tags => "psychology mind", :name_de => "Psychologie und Psyche", :tags_de => "Psychologie Psyche" },
        { :name => "Miscellaneous", :name_de => "Generelle Themen" },
      ] },
      # Society
      { :name => "Society and Culture", :short_name => "Society", :name_de => "Gesellschaft und Kultur", :short_name_de => "Gesellschaft", :children => [
        { :name => "Crime", :name_de => "Kriminalität", :children => [
          { :name => "Crime Prevention", :tags => "crime prevention", :name_de => "Verbrechensverhütung", :tags_de => "Verbrechensverhütung Verbrechen" },
          { :name => "Juvenile Delinquency", :tags => "juvenile delinquency youth crime", :name_de => "Jugendkriminalität", :tags_de => "Jugendkriminalität" },
          { :name => "Law Enforcement", :tags => "'law enforcement' law enforcement officer 'law enforcement officer'", :name_de => "Strafverfolgung", :tags_de => "Strafverfolgung Exekutivorgane Vollzugsbehörde Vollzugsbehörden Gesetzeshüter" },
          { :name => "Organized Crime", :tags => "organized crimes crime mafia", :name_de => "Organisiertes Verbrechen", :tags_de => "'Organisiertes Verbrechen' organisiertes Verbrechen Mafia mafiös" },
          { :name => "Unsolved Crimes", :tags => "unsolved unresolved crimes", :name_de => "Unaufgeklärte Verbrechen", :tags_de => "unaufgeklärte Verbrechen unaufgeklärt" },
          # Types of crime
          { :name => "Abuse", :tags => "abuse abuses", :name_de => "Misshandlung", :tags_de => "Misshandlung Missbrauch Missbräuche" },
          { :name => "Hijacking", :tags => "hijacking", :name_de => "Entführung", :tags_de => "Entführung Piraterie" },
          { :name => "Computer and Internet Crimes", :tags => "computer-crime 'computer crime' 'internet crime' hacking hacker hackers computer computers", :name_de => "Computer- und Internetkriminalität", :tags_de => "Computerkriminalität Internetkriminalität Hacker hacken Computer" },
          { :name => "Domestic Violence", :tags => "domestic violence 'domestic violence'", :name_de => "Häusliche Gewalt", :tags_de => "'Häusliche Gewalt'" },
          { :name => "Drunk Driving", :tags => "drunk driving alcohol drink-driving 'drunk driving'", :name_de => "Autofahren unter Alkoholeinfluss", :tags_de => "'Autofahren unter Alkoholeinfluss' Autofahren Alkoholeinfluss Alkoholeinfluß" },
          { :name => "Fraud", :tags => "fraud fraudulence fraudulency sculduggery swindle deceit", :name_de => "Betrug", :tags_de => "Unterschlagung Betrügerei Betrug Schwindel" },
          { :name => "Genocide", :tags => "genocide", :name_de => "Völkermord", :tags_de => "Völkermord Genozid" },
          { :name => "Graffiti", :tags => "graffiti", :name_de => "Graffiti", :tags_de => "Graffiti" },
          { :name => "Homicide", :tags => "homicide manslaughter 'blood and thunder'", :name_de => "Mord und Totschlag", :tags_de => "'Mord und Totschlag' Mord Totschlag" },
          { :name => "Kidnapping", :tags => "kidnapping kidnap", :name_de => "Menschenraub", :tags_de => "Entführung Menschenraub Kidnapping" },
          { :name => "Tax Evasion", :tags => "tax evasion 'tax evasion' 'fiscal evasion' 'evasion of taxes'", :name_de => "Steuerhinterziehung", :tags_de => "Steuerhinterziehung 'hinterziehen von Steuern'" },
          { :name => "Money Laundering", :tags => "money laundering", :name_de => "Geldwäsche", :tags_de => "Geldwäsche Geldwäscherei" },
          { :name => "Perjury", :tags => "perjury 'false oath'", :name_de => "Meineid", :tags_de => "Eidbruch Meineid" },
          { :name => "Police Brutality", :tags => "police brutality", :name_de => "Polizeiliche Brutalität", :tags_de => "polizeiliche Brutalität Polizei" },
          { :name => "Sex Crimes", :tags => "sex crimes crime 'sex offenses'", :name_de => "Sexualdelikte", :tags_de => "Sexualdelikte Sexualdelikt Sexualkriminell Sexualkriminelle" },
          { :name => "Stalking", :tags => "stalk stalking molesting badger harass harassment sexual harassment", :name_de => "Belästigung", :tags_de => "Belästigung belästigen belästigte belästigt sexuelle Belästigung sexuell belästigen" },
          { :name => "Terrorism", :tags => "terrorism terrorist attack", :name_de => "Terrorismus", :tags_de => "Terrorismus Terrorakt Terroranschlag" },
          { :name => "Theft", :tags => "theft thefts stealing steal", :name_de => "Diebstahl", :tags_de => "Diebstahl Entwendung Klau klauen" },
          { :name => "Torture", :tags => "torture tortures agony anguish bale excruciation tantalization", :name_de => "Folter", :tags_de => "Folter Qual quälen Zappelnlassen" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" },
        ] },
        { :name => "Education", :name_de => "Bildungswesen", :children => [
          { :name => "Elimentary School", :tags => "elimentary school", :name_de => "Grundschule", :tags_de => "Grundschule Schule" },
          { :name => "Secondary Education", :tags => "K12 'High School' school", :name_de => "Sekundarschulbildung", :tags_de => "Sekundarschulbildung Sekundarschulwesen Oberschule Hauptschulbildung Hauptschule Realschulbildung Realschule 'höhere Schulbildung' Schule" },
          { :name => "High School", :tags => "'High School' K12 school", :name_de => "Gymnasium", :tags_de => "Gymnasium Abitur" },
          { :name => "Schools", :tags => "schools school faculty", :name_de => "Schulen", :tags_de => "Schulen Schule Bildungstätte Bildungsstätten Bildungseinrichtung Bildungseinrichtungen Fakultät" },
          { :name => "Teaching", :tags => "teaching", :name_de => "Lehrtätigkeit", :tags_de => "Lehrtätigkeit Unterricht" },
          { :name => "Teachers", :tags => "teacher teachers academic instructor lecturer tutor", :name_de => "Lehrpersonal", :tags_de => "Lehrpersonal Lehrer Studienrat Studienräte Dozent Dozentin Tutor Ausbilder Instrukteur" },
          { :name => "Universities", :tags => "universities university college", :name_de => "Hochschulen", :tags_de => "Hochschulen Hochschule Universität Fachhochschule Akademie" },
          { :name => "Fraternities", :tags => "fraternity fraternities sororities sorority camaraderie", :name_de => "Bruderschaften", :tags_de => "Bruderschaften Bruderschaft Schwesternschaft Schwesternschaften Kameradschaft Kameradschaftsgeist" },
          { :name => "Scholarships", :tags => "scholarships scholarship stipend", :name_de => "Stipendien", :tags_de => "Stipendium Stipendien" },
          { :name => "Kindergarten", :tags => "kindergarten pre-school", :name_de => "Kindergarten", :tags_de => "Kindergarten" },
          { :name => "Pre-school Education", :tags => "pre-school education", :name_de => "Vorschulerziehung", :tags_de => "Vorschule Vorschulerziehung" },
          { :name => "Adult and Continuing Education", :tags => "adult continuing education", :name_de => "Weiterbildung im Alter", :tags_de => "'Weiterbildung im Alter' Weiterbildung Fortbildung" },
          { :name => "Early Childhood Education", :tags => "early childhood education", :name_de => "Frühkindliche Erziehung", :tags_de => "'Frühkindliche Erziehung' Kindergarten Vorschule" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" },
        ] },
        { :name => "Government", :name_de => "Staat und Regierung", :children => [
          { :name => "Constitution", :tags => "constitution", :name_de => "Verfassung", :tags_de => "Konstitution Verfassung" },
          { :name => "Legislature", :tags => "legislature", :name_de => "Gesetzgebung", :tags_de => "Gesetzgebung Gesetz" },
          { :name => "Municipality", :tags => "municipality", :name_de => "Stadtverwaltung", :tags_de => "Stadtverwaltung" },
          { :name => "Local Administration", :tags => "local administration", :name_de => "Kreisverwaltung", :tags_de => "Kreisverwaltung Kreisrat" },
          { :name => "City Council", :tags => "city council", :name_de => "Stadtrat", :tags_de => "Stadtrat Stadtregierung Stadtsenat" },
          { :name => "Federal State Government", :tags => "'State Government' state government", :name_de => "Landesregierung", :tags_de => "Landesregierung Regierung" },
          { :name => "Federal Government", :tags => "federal government", :name_de => "Bundesregierung", :tags_de => "Bundesregierung Regierung" },
          { :name => "Countries", :tags => "countries country nation 'United States' 'United States of America' USA 'United Kingdom' UK", :name_de => "Land", :tags_de => "Land Bund Bundesrepublik Österreich Schweiz Lichtenstein" },
          { :name => "Military", :tags => "military army navy 'air force'", :name_de => "Bundeswehr", :tags_de => "Bundeswehr Militär Heer Luftwaffe Marine" },
          { :name => "Embassies and Consulates", :tags => "embassies embassy consulate consulates", :name_de => "Botschaften und Konsulate", :tags_de => "Botschaften Botschaft Konsulate Konsulat" },
          { :name => "Ethics", :tags => "ethics", :name_de => "Moral und Ethik", :tags_de => "Moral Ethik" },
          { :name => "Intelligence", :tags => "intelligence 'intelligence service'", :name_de => "Geheimdienst", :tags_de => "Geheimdienst BND" },
          { :name => "International Organizations", :tags => "international organizations", :name_de => "Internationale Organisationen", :tags_de => "'Internationale Organisationen'" },
          { :name => "Taxes", :tags => "tax taxes", :name_de => "Steuern", :tags_de => "Steuern Steuer" },
          { :name => "Department for Foreign Affairs", :tags => "'State Department'", :name_de => "Außenministerium", :tags_de => "'Auswärtiges Amt' AA" },
          { :name => "Department of Justice", :tags => "'Department of Justice' 'Ministry of Justice'", :name_de => "Justizministerium", :tags_de => "Justizministerium 'Bundesministerium der Justiz' BMJ" },
          { :name => "Department of Trade and Industry", :tags => "'Department of Trade and Industry' economics ministry 'Ministry of Economics'", :name_de => "Wirtschaftsministerium", :tags_de => "'Bundesministerium für Wirtschaft und Technologie' BMWI Wirtschaft" },
          { :name_de => "Familienministerium", :tags_de => "'Bundesministerium für Familie, Senioren, Frauen und Jugend' BMFSFJ Familie Senioren Frauen Jugend" },
          { :name => "Department of Agriculture", :tags => "'Department of Agriculture' 'Ministry of Agriculture'", :name_de => "Landwirtschaftsministerium", :tags_de => "Ernährung Landwirtschaft Forstwirtschaft Verbraucherschutz" },
          { :name => "Department of Transportation", :tags => "'Department for Transport' 'Department of Transport' transport transportation ministry", :name_de => "Verkehrministerium", :tags_de => "Verkehr Bau Stadtentwicklung 'Bundesministerium für Verkehr, Bau und Stadtentwicklung' BMVBS" },
          { :name => "Department of the Interior", :tags => "'Department of the Interior' interior ministry 'Ministry of the Interior'", :name_de => "Innenministerium", :tags_de => "'Bundesministerium des Innern' 'Innere Sicherheit' BMI" },
          { :name => "Treasury Department", :tags => "'Ministry of Finance' 'The Exchequer' treasury", :name_de => "Finanzministerium", :tags_de => "'Bundesministerium der Finanzen' BMF" },
          { :name => "Department of Labor", :tags => "'Department of Labor' 'Department of Employment' 'Ministry of Labour' labour ministry", :name_de => "Arbeitsministerium", :tags_de => "'Bundesministerium für Arbeit und Soziales' BMAS" },
          { :name => "Department of Defense", :tags => "'Department of Defense' DoD 'Ministry of Defence' MoD", :name_de => "Verteidigungsministerium", :tags_de => "'Bundesministerium der Verteidigung' BMVg" },
          { :name => "Department of Health", :tags => "'Department of Health' 'Ministry of Health'", :name_de => "Gesundheitsministerium", :tags_de => "'Bundesministerium für Gesundheit' BMG" },
          { :name_de => "Umweltministerium", :tags_de => "'
          Bundesministerium für Umwelt, Naturschutz und Reaktorsicherheit' BMU" },
          { :name_de => "Kultusministerium", :tags_de => "'Bildungsministerium' Bildung Forschung" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" },
        ] },
        { :name => "Politics", :name_de => "Politik", :children => [
          { :name => "Parties", :tags => "'political parties' party parties", :name_de => "Parteien", :tags_de => "Partei Parteien" },
          { :name => "News and Media", :tags => "news media", :name_de => "Nachrichten und Medien", :tags_de => "Nachrichten Medien" },
          { :name => "Elections", :tags => "elections election ballot poll vote", :name_de => "Wahl", :tags_de => "Wahl Abstimmung abstimmen wählen Stimme" },
          { :name => "Lobbies", :tags => "lobbies lobby lobbyist stakeholder", :name_de => "Interessengruppen", :tags_de => "Interessengruppen Verband Interessengruppe Interessenvertreter Lobby Lobbies" },
          { :name => "Corruption", :tags => "corruption corrupt", :name_de => "Korruption", :tags_de => "Korruption korrupt" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" },
        ] },
        { :name => "People", :name_de => "Menschen", :children => [
          { :name => "Artists", :tags => "artists artist", :name_de => "Künstler", :tags_de => "Künstler Kunst" },
          { :name => "Celebrities", :tags => "celebrity celebrities", :name_de => "Berühmtheiten", :tags_de => "Berühmtheiten Berühmtheit berühmt" },
          { :name => "Journalists", :tags => "journalist journalists", :name_de => "Journalisten", :tags_de => "Journalisten Journalist Journalistin" },
          { :name => "Missing Persons", :tags => "missing persons missing", :name_de => "Vermisste Personen", :tags_de => "Vermisste Vermißte vermisst" },
          { :name => "Politicians", :tags => "politician politics", :name_de => "Politiker", :tags_de => "Politiker Politik" },
          { :name => "Sexuality", :tags => "sexuality sex intercourse", :name_de => "Sexualität", :tags_de => "Sexualität Sex Geschlechtsverkehr" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" },
        ] },
        { :name => "Relationships", :name_de => "Beziehungen", :children => [
          { :name => "Cheating", :tags => "cheating cheat", :name_de => "Betrug", :tags_de => "Betrug betrügen" },
          { :name => "Bullying", :tags => "bullying harassment", :name_de => "Mobbing", :tags_de => "Terror Mobbing Schikane Beziehungsterror" },
          { :name => "Divorce", :tags => "divorce", :name_de => "Scheidung", :tags_de => "Scheidung" },
          { :name => "Homosexuality", :tags => "homosexuality gay lesbian", :name_de => "Homosexualität", :tags_de => "Homosexualität gleichgeschlechtliche Beziehung gleichgeschlechtlich" },
          { :name => "Extramarital Affairs", :tags => "extramarital cheating cheat", :name_de => "Außereheliche Beziehungen", :tags_de => "'Außereheliche Beziehungen' außerehelich außereheliche Beziehung" },
          { :name => "Incest", :tags => "incest", :name_de => "Inzest", :tags_de => "Inzest Blutschande" },
          { :name => "Marriage", :tags => "marriage married wedding", :name_de => "Ehe", :tags_de => "Ehe Heirat Hochzeit Trauung Verehelichung Verheiratung" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" },
        ] },
        { :name => "Religion and Spirituality", :short_name => "Religion", :tags => "religion spirituality", :name_de => "Religion und Spiritualität", :short_name_de => "Religion", :tags_de => "Religion Spiritualität"},
        { :name => "Environment and Nature", :short_name => "Nature", :name_de => "Natur und Umwelt", :short_name_de => "Natur", :children => [
          { :name => "Conservation", :tags => "conservation 'nature conservancy' 'nature conservation'", :name_de => "Naturschutz", :tags_de => "Naturschutz Umweltschutz Naturschützer Umweltschützer" },
          { :name => "Disaster", :tags => "disaster catastrophe crash accident breakdown", :name_de => "Katastrophe", :tags_de => "Katastrophe Desaster Unfall" },
          { :name => "Forrests", :tags => "forrest forrests tree trees", :name_de => "Wälder", :tags_de => "Wälder Wald" },
          { :name => "Climate Change", :tags => "global climate change", :name_de => "Klimaveränderung", :tags_de => "Klimaveränderung Klimaveränderungen" },
          { :name => "Global Warming", :tags => "global warming", :name_de => "Erderwärmung", :tags_de => "Erderwärmung 'Global Warming'" },
          { :name => "Mountains", :tags => "mountains mountain alps", :name_de => "Berge", :tags_de => "Berg Berge Alpen" },
          { :name => "Lakes", :tags => "lake lakes", :name_de => "Seen", :tags_de => "See Binnensee" },
          { :name => "Oil and Gas", :tags => "oil gas", :name_de => "Öl und Gas", :tags_de => "Öl Gas" },
          { :name => "Environmental Pollution", :tags => "environmental polution", :name_de => "Umweltverschmutzung", :tags_de => "Umweltverschmutzung Umwelt Verschmutzung" },
          { :name => "Waste Management", :tags => "waste management", :name_de => "Abfallbeseitigung", :tags_de => "Abfallbeseitigung Müllabfuhr Entsorgung Müll Abfall" },
          { :name => "Water Resources", :tags => "water resources", :name_de => "Wasserhaushalt", :tags_de => "Wasserhaushalt Wasser" },
          { :name => "Wilderness", :tags => "wilderness desert", :name_de => "Wildnis", :tags_de => "Wildnis Wüste" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" },
        ] },
        { :name => "Families", :tags => "families family", :name_de => "Familien", :tags_de => "Familien Familie" },
        { :name => "Food and Drinks", :short_name => "Food", :name_de => "Ernährung", :children => [
          { :name => "Allergies", :tags => "allergy allergies 'food allergies'", :name_de => "Allergien", :tags_de => "Allergie Allergien Lebensmittelallergie Lebensmittelallergien" },
          { :name => "Drinks", :tags => "drinks drink", :name_de => "Getränke", :tags_de => "Getränk Getränke trinken" },
          { :name => "Food Preservation", :tags => "food preservation 'tinned food'", :name_de => "Konservierung", :tags_de => "Konservierung Konserven konservieren aufbewahren" },
          { :name => "Food Safety", :tags => "food safety", :name_de => "Lebensmittelsicherheit", :tags_de => "Lebensmittelsicherheit Lebensmittel-Sicherheit" },
          { :name => "Food Poisoning", :tags => "food poisoning", :name_de => "Lebensmittelvergiftung", :tags_de => "Lebensmittelvergiftung Vergiftung" },
          { :name => "Drinking Water", :tags => "drinking water", :name_de => "Trinkwasser", :tags_de => "Trinkwasser Trinkwasserqualität" },
          { :name => "Grocery Shopping", :tags => "grocery shopping", :name_de => "Lebensmitteleinkauf", :tags_de => "Lebensmitteleinkauf Lebensmitteleinkäufe" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" },
        ] },
        { :name => "Death and Dying", :name_de => "Sterben und Tot", :children => [
          { :name => "Cemeteries", :tags => "Cemeteries Cemetery", :name_de => "Friedhöfe", :tags_de => "Friedhöfe Friedhof" },
          { :name => "Bereavement", :tags => "bereavement", :name_de => "Trauerfall", :tags_de => "Trauerfall Trauer" },
          { :name => "Euthanasia", :tags => "euthanasia", :name_de => "Sterbehilfe", :tags_de => "Sterbehilfe Euthanasie" },
          { :name => "Funerals", :tags => "funerals funeral", :name_de => "Begräbnisse", :tags_de => "Grab Begräbnis" },
          { :name => "Memorial", :tags => "memorial", :name_de => "Gedenkstätte", :tags_de => "Denkmal Gedenkstätte Mahnmal Grab" },
          { :name => "Suicide", :tags => "suicide suicidal", :name_de => "Selbstmord", :tags_de => "Selbstmord Freitod Selbstmörder Selbsttötung Suizid" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" },
        ] },
        { :name => "Disabilities", :tags => "disability disabilities disabled disablement", :name_de => "Behinderungen", :tags_de => "Behinderungen Behinderung behindert Behinderte" },
        { :name => "Etiquette", :tags => "etiquette behavior 'social behavior' 'ethical code'", :name_de => "Umgangsformen", :tags_de => "Umgangsformen Benehmen Anstandsregel Etikette" },
        { :name => "Home and Garden", :short_name => "Home", :name_de => "Heim und Garten", :short_name_de => "Zuhause", :children => [
          { :name => "Appliances", :tags => "appliances 'domestic appliances' 'domestic appliance'", :name_de => "Haushaltsgeräte", :tags_de => "Haushaltsgeräte Haushaltsgerät" },
          { :name => "Lawn", :tags => "lawn lawnmower mower", :name_de => "Rasen", :tags_de => "Rasen Rasenmäher" },
          { :name => "Lighting", :tags => "lights light", :name_de => "Beleuchtung", :tags_de => "Beleuchtung Belichtung Licht" },
          { :name => "Lightning Strike", :tags => "lightning strike", :name_de => "Blitzeinschlag", :tags_de => "Blitz Blitzeinschlag" },
          { :name => "Pest Control", :tags => "bugs 'pest control' biological pest-control pesticides", :name_de => "Schädlingsbekämpfung", :tags_de => "Schädlingsbekämpfung Kammerjäger Käfer Insekten Pestizide" },
          { :name => "Pools, Spas, and Saunas", :tags => "pool spa sauna pools spas saunas swimmingpool jacuzzi tub hottub", :name_de => "Pools, Bäder und Sauna", :tags_de => "Pool Swimmingpool Jacuzzi Whirlpool Sprudelbad" },
          { :name => "Repair and Improvement", :tags => "repair improvment fixing fix", :name_de => "Reparieren und Verschönern", :tags_de => "reparieren Reparatur Verschönerung verschönen" },
          { :name => "Safety", :tags => "safety alarm security system", :name_de => "Sicherheit", :tags_de => "Sicherheit Alarm Sicherheitssystem Sicherheitssysteme" },
          { :name => "Landscape Architecture", :tags => "landscape architecture design planning", :name_de => "Landschaftsgestaltung", :tags_de => "Landschaftsgestaltung Landschaftsplanung Landschaftsarchitektur Architektur Architekt" },
          { :name => "Interior Design", :tags => "interior design architecture architect", :name_de => "Innenarchitektur", :tags_de => "Innenarchitektur Architekt Architektur" },
          { :name => "Home Entertainment", :tags => "home entertainment TV radio stereo Hi-Fi DVD video multi-media", :name_de => "Home Entertainment", :tags_de => "'Home Entertainment' Unterhaltung Fernseher Radio TV Video Videospiel Videospiele" },
          { :name => "Cleaning", :tags => "clean cleaning wash", :name_de => "Reinigung", :tags_de => "Reinigung reinigen Saubermachen" },
          { :name => "Miscellaneous", :name_de => "Generelle Themen" },
        ] },
        { :name => "Museums and Exhibits", :short_name => "Exhibitions", :tags => "museum museums exhibit exhibits", :name_de => "Museen und Ausstellungen", :short_name_de => "Ausstellungen",  :tags_de => "Museum Museen Ausstellung Ausstellungen" },
        { :name => "Pets", :tags => "pets pet animals animal", :name_de => "Haustiere", :tags_de => "Haustiere Haustier Tiere Tier" },
        { :name => "Social Organizations", :tags => "social organizations", :name_de => "Soziale Einrichtungen", :tags_de => "Soziale Einrichtungen" },
        { :name => "Miscellaneous", :name_de => "Generelle Themen" }
      ] }
    ]

    def self.up
      save_settings

      # destroy all fromer categories if present: Legal / Recht & Justiz
      Category.find(:all, :conditions => "parent_id IS NULL").each do |old_category|
        destroy_category(old_category)
      end

      # create new categories
      add_nodes(CategoryContent::ROOTS)

      restore_settings
    end

    def self.down
      save_settings
      remove_nodes(CategoryContent::ROOTS)
      restore_settings
    end

    def self.save_settings
      self.tag_list_delimiter = Category.tag_list_delimiter 
      self.tag_filter_active = Category.tag_filter_active
      self.translate_tags = Category.translate_tags

      Category.tag_list_delimiter = ' '
      Category.tag_filter_active = false
      Category.translate_tags = true
    end

    def self.restore_settings
      Category.tag_list_delimiter = self.tag_list_delimiter
      Category.tag_filter_active = self.tag_filter_active
      Category.translate_tags = self.translate_tags
    end

    # Recursive method to import category tree
    def self.add_nodes(nodes, parent=nil)
      nodes.each do |node|
        category = Category.create(node.reject {|k, v| :children==k }.merge(:parent => parent))
        puts "adding '#{category.to_s}'"
        add_nodes(node[:children], category) if node[:children]
      end
    end

    # Gracefully removes all categories defined in this migration and 
    # all of their sub-categories. Used in self.down
    def self.remove_nodes(nodes)
      nodes.each do |node|
        category = Category.find(
          :first,
          :conditions => node.reject {|k, v| :children==k || k.to_s.index('tags') }.merge(:parent_id => nil)
        )
        puts "removing '#{category.to_s}'." unless category.to_s.empty?
        self.destroy_category(category)
      end
    end

    # Recursively decent deletes a root category and all of its subcategories
    # plus gracefully removes tags in case they are not associated to other tags
    def self.destroy_category(category)
      if category
        category.children.each do |child|
          self.destroy_category(child)
        end
        tag_ids = category.tags.collect {|t| t.id }
        category.destroy
        # removes all tags that have no taggings point to it and 
        # that were associated with the category we just destroyed
        unless tag_ids.empty?
          Tag.destroy_all([
            "id NOT IN (?) AND id IN (?)",
            Tagging.find(:all, :select => "DISTINCT taggings.tag_id").collect {|t| t.tag_id },
            tag_ids
          ])
        end
      end
    end

  end
  #--- end update category class
  
end