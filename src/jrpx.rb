VERSION = "06-2018_0.0.7"
JRUBYJAR_LINK = "https://s3.amazonaws.com/jruby.org/downloads/9.2.0.0/jruby-complete-9.2.0.0.jar"

LibGDX_APP_ADAPTER_TEMPLATE_FILE = "
java_import com.badlogic.gdx.ApplicationAdapter
java_import com.badlogic.gdx.Gdx
java_import com.badlogic.gdx.graphics.GL20
java_import com.badlogic.gdx.graphics.Texture
java_import com.badlogic.gdx.graphics.g2d.SpriteBatch

class %s < ApplicationAdapter
    def create
        @batch = SpriteBatch.new()
        @img = Texture.new(\"assets/badlogic.jpg\")
    end

    def render
        Gdx.gl.glClearColor(1, 0, 0, 1)
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT)
        @batch.begin()
        @batch.draw(@img, 0, 0)
        @batch.end()
    end

    def dispose
        @batch.dispose()
    end
end
"

LibGDX_DESKTOP_LAUNCHER_TEMPLATE = "
require './%s.rb'

java_import com.badlogic.gdx.backends.lwjgl.LwjglApplication
java_import com.badlogic.gdx.backends.lwjgl.LwjglApplicationConfiguration

config = LwjglApplicationConfiguration.new()
LwjglApplication.new(%s.new(), config)
"

def show_help
    puts 'Example : jrp [method [arg]]',
        '',
        '   -v, --version to see the version',
        '',
        'Methods: ',
        '   new [project Name]        :Create New Project',
        '   new -lgdx [project Name]  :Create New LibGDX project',
        '  *Inside project folder*     ',
        '   run                       :Run Project',
        '   dist,dist [output]        :compiles into a final jar[CLASS]',
        '   dist:rb, dist:rb [output] :compiles into a final boostrap jar[RB]',
        ' Additionals',
        '  jrp run [-w [folder]] [-l]',
        '     example -w: `jrp run -w imgs` will run inside the folder imgs',
        '     so can access the files inside her without need to run dist',
        '     only supports 1 level folder yet',
        '',
        '     example -l: `jrp run -l` or `jrp run -w folder -l` will leave',
        '     the resultant runner file in  last/runner.rb',
        '     this will help you fix errors of result program.'
end

def get_value val
    (/#{val}:\s*(.{1,})/.match File.read('./jrp.p'))[1]
end

def get_main_class
    get_value 'Main-Class'
end

def get_class_path
    if Dir.exist? './libs'
        Dir['./libs/*.jar'].join ':'
    else
        abort 'No library dir found. [ Where Example.jar\'s should be ]'
    end
end

def check_if_is_jrpx
    File.exist? './jrp.p'
end

def file_not_found
    abort 'BUILD FAILED - FILE NOT FOUND - ' + $main_class 
end

def download file, link, message='Downloading file'
    require 'net/http'

    uri = URI(link)

    Net::HTTP.start(uri.host, uri.port, use_ssl:(uri.scheme=='https')) do |http|
        request = Net::HTTP::Get.new uri
        http.request request do |response|
            file_size = response['content-length'].to_i
            amount_downloaded = pro = 0
            progress = ""
            print message+' '
            open file, 'wb' do |io| # 'b' opens the file in binary mode 
                response.read_body do |chunk|
                    io.write chunk
                    amount_downloaded += chunk.size
                    last_pro = pro
                    pro = (amount_downloaded.to_f / file_size * 100)
                    if pro.round > last_pro.round
                        print "\b"*progress.size
                        progress = "%d%%" % pro
                        print progress
                    end
                end
            end
            print "\n"
        end
    end
end

def parse_require_calls str
    str.scan(/\s*require\s*\(?['|"](.+?)['|"]\)?/).select {|name|
        _name = name[0].strip()
        _name[0..1] == './' && _name[-4..-1] != '.jar'
    }.map {|name|
        _name = name[0].strip()
        _name[-3..-1] == '.rb' ? _name : _name+'.rb'
    }
end

def clear_require_calls str, requires
    requires.each do |r|
        _r = r[0..-4]
        str = str.gsub(/\s*require\s*\(?['|"]\s*#{_r}(\.rb)?\s*['|"]\)?/, '')
    end
    str
end

# The program starts here

if ARGV[0] != nil
    if ARGV[0] == '-v' || ARGV[0] == '--version'
        puts VERSION
        exit
    end
    case ARGV[0]
    when 'new'
        # Create struture folder and files
        if ARGV[1] != nil
            $is_lib_gdx = false
            if ARGV[1] == '-lgdx'
                if ARGV[2] != nil
                    $project_name = ARGV[2]
                    $is_lib_gdx = true
                else
                    abort 'Project name not specified!'
                end
            else
                # Assume that the second argument is the project name
                $project_name = ARGV[1]
            end

            # Create project
            Dir.mkdir $project_name
            Dir.chdir './' + $project_name
            Dir.mkdir 'src'
            Dir.mkdir 'libs'
            File.new './src/' + $project_name+'.rb', 'w'

            download './libs/jruby.jar', JRUBYJAR_LINK, message='Downloading jruby library '

            if $is_lib_gdx
                # Create LibGDX struture
                Dir.mkdir 'assets'

                hoster = 'https://libgdx.badlogicgames.com/ci/nightlies/dist/'
                # Download LibGDX dependencies for desktop dev
                puts "Downloading LibGDX dependecies"

                ['gdx.jar',
                 'gdx-natives.jar',
                 'gdx-backend-lwjgl.jar',
                 'gdx-backend-lwjgl-natives.jar'].each do |file|
                    download "./libs/#{file}", "#{hoster}/#{file}", message='Downloading ' + file
                end

                download './assets/badlogic.jpg', 'http://i.imgur.com/joJOP1R.jpg', message='Downloading badlogic logo'
                
                # Writing files
                File.write "./src/#{$project_name}.rb", LibGDX_APP_ADAPTER_TEMPLATE_FILE % $project_name
                File.write './src/desktopLauncher.rb', LibGDX_DESKTOP_LAUNCHER_TEMPLATE % ([$project_name]*2)

                File.write './jrp.p', "Main-Class: desktopLauncher\nProject-Type: LibGDX\n"
            else
                File.write './jrp.p', "Main-Class: #{$project_name}\nProject-Type: project\n"
            end
            Dir.chdir '..'
            puts "Project setup finished successfully"
        else
            abort "Project name not specified!"
        end
    when 'run'
        # Run as ruby file
        check_if_is_jrpx

        runned = false

        folder_name = Dir.pwd

        if ARGV[1] != nil
            if ARGV[1] == '-w'
                folder_name = ARGV[2] if ARGV[2]!=nil
            else
                if ARGV[1] == '-l'
                    runned = true
                    puts "-> runned file will be in last/runner.rb"
                end
            end
        end
        if ARGV[3] != nil && ARGV[3] == '-l'
            runned = true
            puts "-> runned file will be in last/runner.rb"
        end

        final_program = ""

        main_class = get_main_class
        
        start_code = File.read "./src/#{main_class}.rb"

        require_calls = parse_require_calls(start_code).uniq

        start_code = clear_require_calls(start_code, require_calls)
        
        # Load of jars not by user. So it only happens here.
        final_program << "Dir['./libs/*.jar'].each { |jar| require jar unless jar.include? 'jruby' }\n"

        Dir.chdir './src' do
            require_calls.each do |r|
                required = File.read r
                require_calls.concat(parse_require_calls(required).uniq)
                require_calls.uniq!
                # require_calls.each do |_r|
                #     _required = File.read _r
                #     require_calls << parse_require_calls(_required).uniq
                #     require_calls.uniq!
                # end
            end
            require_calls.reverse.each { |r| final_program << ("\n" + File.read(r)) }
        end

        # Add the last and most important
        final_program << ("\n" + start_code)

        if runned
            Dir.mkdir './last' if !Dir.exist? './last'
            File.write './last/runner.rb', final_program
        end

        begin
            Dir.chdir folder_name do 
                eval final_program
            end
        rescue Exception => e
            puts e.message, e.backtrace.inspect
        end
    when 'dist'
        abort 'Not developed yet'
    when 'dist:rb'
        abort 'Not developed yet'
    when '--help', '-h'
        show_help
    end
else
    puts 'No option specified'
    show_help
end