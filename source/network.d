/* A library of tools for creating .SIF network files.
 *
 * Author: Jonathan Samson
 * Date: 17 August 2020
 */
module network;
import std.format;
import consensus;
import scans;
import mscosine;
import std.conv;
import std.stdio;

string make_edge(string node_1, string node_2, string edge_type = "a")
/* Populates a string that represents an edge in the network.
 * Arguments:
 *	node_1 - The first node to be connected by the edge.
 *	node_2 - The second node to be connected by the edge.
 *	edge_type - The edge type for the edge; allows different edges.
 * Returns:
 *	edge - The string that represents an edge in a .SIF file.
 */
{
	string edge = "%s %s %s\n".format(node_1, edge_type, node_2);
	return edge;
}
unittest
{
	string node_1 = "First";
	string node_2 = "Second";
	string edge = "Is Connected To";
	assert(make_edge(node_1, node_2, edge) == 
			"First Is Connected To Second\n");
	assert(make_edge(node_1, node_2) == "First a Second\n");
}

string make_node(string node)
/* Populates a string that represents a node in the network.
 * Arguments:
 *	node - The name of the node to add.
 * Returns:
 *	node_string - The string reprensenting the node in a .SIF file.
 */
{
	string node_string = format!"%s\n"(node);
	return node_string;
}
unittest
{
	string my_node = "First";
	assert(make_node(my_node) == "First\n");
}

ConsensusScan[] generate_nodes(
		MSXScan[] scans, 
		double peak_threshold,
		float node_cutoff)
/* Generates all nodes for a network file.
 * Arguments:
 *	scans - The MSXScans to be included in the network.
 *	peak_threshold - M/z tolerance for peaks.
 *	node_cutoff - Cosine score to be in the same node.
 */
{
	ConsensusScan[] consensus_list;
	foreach(scan; scans)
	{
		bool consensus_not_found = true;
		foreach(consensus; consensus_list)
		{
			if(find_cosine_score(
						consensus.consensus_peaks, 
						scan.peaks,
						peak_threshold) >= 
					node_cutoff)	
			{
				consensus.add_scan(scan);
				consensus_not_found = false;
				break;
			}
		}
		if (consensus_not_found)
		{
			ConsensusScan this_scan = new ConsensusScan;
			this_scan.included_scans ~= scan;
			this_scan.consensus_peaks = scan.peaks;
			this_scan.peak_threshold = peak_threshold;
			consensus_list ~= this_scan;
		}
	}
	return consensus_list;
}
unittest
{
	MSXScan scan1 = new MSXScan;
	MSXScan scan2 = new MSXScan;
	MSXScan[] scans = [scan1, scan2];
	real[real] peaks1 = [
		100.1:	1000,
		200.1:	10000,
		300.1:	0,
	];
	scan1.peaks = peaks1;
	scan2.peaks = peaks1;
	assert(generate_nodes(scans, 0.1, 0.9).length == 1);
}

void generate_network_file(
	MSXScan[] scans,
	string output_file,
	double peak_threshold,
	float node_cutoff,
	float edge_cutoff)
/* Creates a network file based on cosine score.
 * Arguments:
 *	scans - The MSXScans to be included in the network.
 *	output_file - The file to save the network in.
 *	peak_threshold - M/z tolerance for peaks.
 *	node_cutoff - Cosine score to be in the same node.
 *	edge_cutoff - Cosine score to create an edge.
 */
{
	ConsensusScan[] nodes = generate_nodes(
			scans,
			peak_threshold,
			node_cutoff);
	string output = "";
	int[] edges_per_node;
	edges_per_node.length = nodes.length;
	for (int i = 0; i < nodes.length - 1; ++i)
	{
		int edges = 0;
		for (int j = i + 1; j < nodes.length; ++j)	
		{
			if (find_cosine_score(nodes[i].consensus_peaks, 
						nodes[j].consensus_peaks) >= 
					edge_cutoff)
			{
				output ~= make_edge(i.to!string, j.to!string);
				++edges_per_node[i];
				++edges_per_node[j];
			}
		}
		if (edges_per_node[i] == 0)
			output ~= make_node(i.to!string);
	}
	auto file = File(output_file, "w");
	file.write(output);
	file.close();
	return;
}
