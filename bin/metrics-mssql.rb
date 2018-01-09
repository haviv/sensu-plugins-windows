#! /usr/bin/env ruby
#


require 'sensu-plugin/metric/cli'
require 'socket'
require 'csv'

#
# MSSQL Metrics
#
class MSSQLMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to prepend to .$parent.$child, ',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.sql"

  option :database,
         short: '-d database',
         default: '_Total'



def run
  IO.popen("typeperf -sc 1 \"SQLServer:Access Methods\\Forwarded Records/sec\" \"SQLServer:Access Methods\\Page Splits/sec\" \"SQLServer:Access Methods\\Full Scans/sec\"  \"SQLServer:Buffer Manager\\Buffer cache hit ratio\" \"SQLServer:Buffer Manager\\Page life expectancy\" \"SQLServer:General Statistics\\Processes blocked\" \"SQLServer:SQL Statistics\\Batch Requests/sec\" \"SQLServer:SQL Statistics\\SQL Compilations/sec\" \"SQLServer:SQL Statistics\\SQL Re-Compilations/sec\" \"SQLServer:Databases(#{config[:site]})\\Data File(s) Size (KB)\" \"SQLServer:Databases(#{config[:site]})\\Log File(s) Size (KB)\"  ") do |io|
    CSV.parse(io.read, headers: true) do |row|
      row.each do |k, v|
          next unless v && k
          break if v.start_with? 'Exiting'

          path = k.split('\\')
          ifz = path[3]
          metric = path[4]
          next unless ifz && metric
          ifz_name = ifz.tr('.', ' ')
          value = format('%.2f', v.to_f)
          name = [config[:scheme], config[:site], ifz_name, metric].join('.').tr(' ', '_').tr('{}', '').tr('[]', '')
          output name, value
      end
    end 
  end
  ok
  end
end
