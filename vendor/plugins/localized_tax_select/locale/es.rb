# Taxes across countries
{:es => {
    :taxes => {
      :DE => {
        :VATIN => {
          :name => 'Número de IVA',
          :short_name => 'UStId.',
          :example => 'DE123456789',
          :url => 'http://www.bzst.bund.de/',
          :regexp => "^DE[0-9]{9}"
        }
      },
      :ES => {
        :VATIN => {
          :name => 'Número de Identificación Fiscal',
          :short_name => 'NIF',
          :example => 'ES123456789',
          :url => 'http://es.wikipedia.org/wiki/Número_de_identificación_fiscal',
          :regexp => "^ES[0-9a-z]{1}[0-9]{7}[0-9a-z]{1}$"
        }
      },
      :AR => {
        :DNI => {
          :name => "Documento Nacional de Identidad",
          :short_name => "DNI",
          :example => '123456789012',
          :url => 'http://www.mininterior.gov.ar/',
          :regexp => "^[0-9]{12}"
        }
      },
      :CL => {
        :RUT => {
          :name => 'Rol Único Tributario',
          :short_name => 'RUT',
          :example => '30.686.957-X',
          :url => 'http://es.wikipedia.org/wiki/Rol_Único_Tributario',
          :regexp => "^[0-9]{2}\.?[0-9]{3}\.?[0-9]{3}-?[a-z]{1}$"
        }
      },
  		:US => {
        :SSN => {
          :name => "Número de Seguro Social",
          :short_name => 'SSN',
          :example => '000-00-0000',
          :url => "https://sa1.www4.irs.gov/sa_vign/",
          :regexp => "^[0-9]{3}-?[0-9]{2}-?[0-9]{4}"
        },
        :EIN => {
          :name => "Número de Identificación Patronal",
          :short_name => 'EIN',
          :example => '00-0000000',
          :url => "http://www.irs.gov/businesses/small/article/0,,id=98350,00.html",
          :regexp => "^[0-9]{2}-?[0-9]{7}"
        },
        :ITIN => {
          :name => "Individual Tax Identification Number",
          :short_name => 'ITIN',
          :example => '900-70-0000',
          :url => "http://www.irs.gov/individuals/article/0,,id=96287,00.html",
          :regexp => "^900-?[0-9]{2}-?[0-9]{7}"
        }
      }
    }
  } 
}
