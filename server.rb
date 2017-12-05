require 'sinatra'
require 'net/ssh'


get '/' do
  send_file 'views/index.html'
end


post '/execute' do
  # check if the textarea or the file upload
  # field was used for giving the input
  if params[:input].length > 0
    # the textarea was used
    input = params[:input]
  else
    # the file upload field was used
    file = params[:file][:tempfile]
    input = file.read.encode('utf-8').chomp.gsub("\n", "\r\n")
  end

  @js_input = input.gsub("\r\n", "\\r\\n")
  @input = input.gsub("\n", "<br>")
  @output = execute_shell_script(input).gsub("\n", "<br>")

  # remove the deprecated warning
  @output.gsub(/DEPRECATED.*for it\.\n\n/m, "")

  # return output
  erb :output
end


def execute_shell_script(input)

  hostname = ENV['hostname']
  username = ENV['username']
  password = ENV['password']

  input_filename = "#{Time.now.to_i}.txt"
  output_filename = "output-#{input_filename}"

  cmds = [
    "cd /home/bduser/slk-giraph",

    "echo '#{input}' > #{input_filename}",

    "hadoop dfs -put #{input_filename} slk-giraph",

    "hadoop jar giraph-examples-1.1.0-for-hadoop-2.6.0-jar-with-dependencies.jar org.apache.giraph.GiraphRunner -Dgiraph.metrics.enable=true org.apache.giraph.examples.scc.SccComputation -vip slk-giraph/#{input_filename} -vif org.apache.giraph.examples.scc.SccLongLongNullTextInputFormat -op slk-giraph/#{output_filename} -vof org.apache.giraph.io.formats.IdWithValueTextOutputFormat -w 1 -ca giraph.zkList=orion-00:2181 -ca giraph.checkpointFrequency=0 -yj giraph-examples-1.1.0-for-hadoop-2.6.0-jar-with-dependencies.jar -mc org.apache.giraph.examples.scc.SccPhaseMasterCompute"
  ]

  begin
    # connect using ssh
    ssh = Net::SSH.start(hostname, username, password: password)

    # execute all commands
    ssh.exec! cmds.join('; ')

    # execute the last command
    res = ssh.exec! "#{cmds[0]}; hadoop dfs -cat slk-giraph/#{output_filename}/part-m-00001"

    # close connection
    ssh.close

    # return result
    return res
  rescue
    puts "Unable to connect to #{hostname} using #{username}/#{password}"
  end
end
