#!/usr/bin/env ruby

# Import Script to import JAR Files of an enterprise
# Distribution into a local maven repository or
# into a nexus repository.
#
# written by Juergen Hoffmann <buddy@redhat.com>
# last edited 2012-10-02

require 'optparse'
require 'nokogiri'



options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: import_libraries.rb [options]"

  options[:verbose] = false
  opts.on('-V', '--verbose', 'Be more verbose' ) do
    options[:verbose] = true
  end

  options[:soap_home] = nil
  opts.on( '-s', '--soa-p-home PATH', 'The Home Directory of SOA-P') do |path|
    options[:soap_home] = path
  end

  options[:groupid] = "com.redhat"
  opts.on( '-g', '--groupId STRING', 'The groupId to use in the maven Descriptor (defaults to "com.redhat")') do |groupid|
    options[:groupid] = groupid
  end

  options[:version] = "5.3.0-SOA-P"
  opts.on( '-v', '--version STRING', 'The version String to use in the maven Descriptor (defaults to "5.3.0-SOA-P")') do |version|
    options[:version] = version
  end

  options[:out_dir] = "."
  opts.on( '-d', '--output-directory STRING', 'The Output Directory for the generated client pom.xml (defaults to ".")') do |directory|
    options[:out_dir] = directory
  end

  options[:work_dir] = "."
  opts.on( '-w', '--work-directory STRING', 'The Working Directory in which the generated bom is stored (defaults to ".")') do |directory|
    options[:work_dir] = directory
  end

  options[:dry_run] = false
  opts.on( '-t', '--dry-run', 'Do not do anything, just print what would be done') do
    options[:dry_run] = true
  end

  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts ""
    puts "This Script will go through your Enterprise Installation and seek for jars at known locations"
    puts "It will then take those jars and import them into your local maven repo using mvn install:install-file"
    puts "The script will also generate a bom (see http://docs.codehaus.org/display/MAVEN/Importing+Managed+Dependencies)"
    puts "and import it into your local repo. A child pom making use of this bom is generated as well."
    puts ""
    puts opts
    exit
  end
end

# Parse the command-line. Remember there are two forms
# of the parse method. The 'parse' method simply parses
# ARGV, while the 'parse!' method parses ARGV and removes
# any options found there, as well as any parameters for
# the options. What's left is the list of files to resize.
optparse.parse!

if options[:soap_home] == nil
  puts "ERROR: You have to configure the SOA-P Home Directory"
  puts optparse.help
  exit
end

# This Class just grants easy access to the Information needed
# of each specific jar file. we need the complete path for the
# mvn install:install-file target, we need the default version,
# which will be overridden if there is a version defined in the
# jar filename etc.
# we need the artifactId etc.
class Jarfile < BasicObject

  # @param [String] filename
  # @param [String] version
def initialize(filename, version)
    @filename = filename
    @version = version
    if temp_version = filename[/-([\d+{1,3}\.A-Z]+).jar/,1]
      @version = temp_version
    end
    @artifactId = filename[/.+\/(.+?)(-\d|.jar)/,1]
    if @artifactId.to_s.end_with?"-"
      @artifactId = @artifactId[0..-2]
    end
  end

  def filename
    @filename
  end

  def version
    @version
  end

  def artifactId
    @artifactId
  end
end


directories = [options[:soap_home] + "/jboss-esb/client",
               options[:soap_home] + "/jboss-esb/server/default/lib",
               options[:soap_home] + "/jboss-esb/server/default/deploy/jbossesb.esb",
               options[:soap_home] + "/jboss-esb/server/default/deploy/jbossesb.sar/lib",
               options[:soap_home] + "/jboss-esb/server/default/deploy/jbpm.esb",
               options[:soap_home] + "/jboss-esb/server/default/deploy/jbrules.esb",
               options[:soap_home] + "/jboss-esb/server/default/deploy/smooks.esb",
               options[:soap_home] + "/jboss-esb/server/default/deploy/soap.esb",
               options[:soap_home] + "/jboss-esb/server/default/deploy/spring.esb",
               options[:soap_home] + "/jboss-esb/server/default/deploy/jbossesb-registry.sar"]

jarlist = []

directories.each do |dir|
  Dir.entries(dir).each do |f|
     if f.to_s.end_with?".jar"
       jarlist.push(Jarfile.new(dir + "/" + f.to_s, options[:version]))
     end
  end
end

builder = Nokogiri::XML::Builder.new do |xml|
  xml.project {
    xml.modelVersion  "4.0.0"
    xml.groupId       options[:groupid]
    xml.artifactId    "soa-p-bom"
    xml.version       options[:version]
    xml.packaging     "pom"
    xml.dependencyManagement {
      xml.dependencies {
        jarlist.each do |jar|
          xml.dependency {
            xml.groupId     options[:groupid]
            xml.artifactId  jar.artifactId
            xml.version     jar.version
          }
        end
      }
    }
  }
end

if options[:verbose] || options[:dry_run]
  puts builder.to_xml
end

unless options[:dry_run]
  document = builder.to_xml
  File.open(options[:work_dir]+"/generated-parent-pom.xml", "w") do |f|
    f.puts document
  end
end

builder = Nokogiri::XML::Builder.new do |xml|
  xml.project {
    xml.modelVersion  "4.0.0"
    xml.groupId       "your-group-id"
    xml.artifactId    "your-project-name"
    xml.packaging     "jar"
    xml.name          "Enter the Name of your Project"
    xml.version       "0.0.1-SNAPSHOT"
    xml.dependencyManagement {
      xml.dependencies {
        xml.dependency {
          xml.groupId     options[:groupid]
          xml.artifactId  "soa-p-bom"
          xml.version     options[:version]
          xml.type        "pom"
          xml.scope       "import"
        }
      }
    }
    xml.dependencies {
      xml.dependency {
        xml.groupId     "your-other-dependency"
        xml.artifactId  "artifact"
        xml.version     "1.0.0"
      }
    }
  }
end

if options[:verbose] || options[:dry_run]
  puts builder.to_xml
end

unless options[:dry_run]
  document = builder.to_xml
  File.open(options[:out_dir]+"/pom.xml", "w") do |f|
    f.puts document
  end
end

jarlist.each_with_index do |jar, i|
  if options[:dry_run]
    puts "mvn install:install-file -Dfile=#{jar.filename} -DgroupId=com.redhat -DartifactId=#{jar.artifactId} -Dversion=#{jar.version} -Dpackaging=jar -DgeneratePom=true -DcreateChecksum=true"
  else
    if options[:verbose]
      puts "mvn install:install-file -Dfile=#{jar.filename} -DgroupId=com.redhat -DartifactId=#{jar.artifactId} -Dversion=#{jar.version} -Dpackaging=jar -DgeneratePom=true -DcreateChecksum=true"
    end
    output = `mvn install:install-file -Dfile=#{jar.filename} -DgroupId=com.redhat -DartifactId=#{jar.artifactId} -Dversion=#{jar.version} -Dpackaging=jar -DgeneratePom=true -DcreateChecksum=true`
    if options[:verbose]
      puts output
    end
  end
end

# Finally install the generated generated-parent-pom.xml
if options[:dry_run]
  puts "mvn install -f #{options[:work_dir]}/generated-parent-pom.xml"
else
  if options[:verbose]
    puts "mvn install -f #{options[:work_dir]}/generated-parent-pom.xml"
  end
  output = `mvn install -f #{options[:work_dir]}/generated-parent-pom.xml`
  if options[:verbose]
    puts output
  end
end
