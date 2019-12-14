# Start hadoop services first
start-yarn.sh
start-dfs.sh

# Remove input directory
# hadoop fs -rm -r input_dir/

# Create input directory
# hadoop fs -mkdir -p input_dir/

# Place input data in input directory
# hadoop fs -put /home/lear/data/* input_dir
# hadoop fs -put /home/lear/data_full/* input_dir
# hadoop fs -put /home/lear/data/2012-02-city-of-london-street.csv input_dir
# hadoop fs -put /home/lear/sample.txt input_dir

#Remove output directory
hadoop fs -rm -r output_dir/

#Compile and run program
sudo javac -classpath hadoop-core-1.2.1.jar -d crime CrimeCount.java
sudo jar -cvf crime.jar -C crime/ .
hadoop jar crime.jar hadoop.CrimeCount input_dir output_dir


# Check output
# hadoop fs -ls output_dir/
hadoop fs -cat output_dir/part-00000
