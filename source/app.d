import std.stdio;
import consensus;
import network;
import std.getopt;
import scans;
import mscosine;
import mzxmlparser;

void main(string[] args)
{
	string input_file, output_file;
	double peak_threshold;
	float node_cutoff, edge_cutoff;

	auto helpInformation = getopt(
			args,
			"input|i", "The input file in .mzxml format",
			&input_file,
			"output|o", "The output file in .SIF format",
			&output_file,
			"peak-threshold|p", "The threshold for two peaks " ~
			"to be considered the same m/z", &peak_threshold,
			"node-cutoff|n", "The cosine score cutoff for two " ~
			"scans to be considered the same node", &node_cutoff,
			"edge_cutoff|e", "The cosine score cutoff for two " ~
			"nodes to have an edge between them", &edge_cutoff
			);
	if(helpInformation.helpWanted)
	{
		defaultGetoptFormatter(
				stdout.lockingTextWriter(),
				"Generates a network of scans based on " ~
				"cosine scores.",
				helpInformation.options,
				"  %*s\t%*s%*s%s\n");
		return;
	}
	if (input_file[$-6..$] != ".mzXML")
		throw new Exception("Invalid input file extension.");
	string file_contents = read_file(input_file);
	MSXScan[] scans;
	scans = parse_mzxml(file_contents);
	generate_network_file(
			scans,
			output_file,
			peak_threshold,
			node_cutoff,
			edge_cutoff);
}
