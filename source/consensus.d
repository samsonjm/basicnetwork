/* A library for making consensus scans based on cosine scores.
 *
 * Author: Jonathan Samson
 * Date: 17 August 2020
 */

module consensus;
import scans;
import mscosine;

class ConsensusScan
{
	real[real] consensus_peaks;
	double peak_threshold;
	MSXScan[] included_scans;

	void add_scan(MSXScan new_scan)
	/* Adds a scan to the consensus, recalculating consensus_peaks.
	 * Arguments:
	 *	new_scan - The scan to add to the list.
	 */
	{
		consensus_peaks = combine_peak_lists(
				consensus_peaks,
				included_scans.length,
				new_scan.peaks,
				1,
				peak_threshold);
		included_scans ~= new_scan;
		return;
	}

	void add_consensus(ConsensusScan new_consensus)
	/* Adds another consensus to this consensus.
	 * Arguments:
	 *	new-consensus - The consensus to add to this one.
	 */
	{
		consensus_peaks = combine_peak_lists(
				consensus_peaks,
				included_scans.length,
				new_consensus.consensus_peaks,
				new_consensus.included_scans.length,
				peak_threshold);
		included_scans ~= new_consensus.included_scans;
		return;
	}

}

real[real] combine_peak_lists(
		real[real] list1, 
		ulong weight1, 
		real[real] list2,
		ulong weight2,
		double threshold)
/* Finds the weighted concensus scan between two peak lists.
 * Arguments:
 *	list1 - The first list to be part of the consensus.
 *	weight1 - The weight of the first list.
 *	list2- The second list to be part of the consensus.
 *	weight2 - The weight of the second list.
 *	threshold - Difference for peaks to be the same m/z
 * Returns:
 *	consensus_peaks - The weighted consensus.
 *
 * The average intensity will be calculated for each peak
 * present in either list and added to consensus peaks.  The 
 * weight represents the number of scans that each list
 * represents, so that a proper averaging of two differently-
 * sized lists can occur.
 */
{
	real[real] consensus_peaks;
	ulong total = weight1 + weight2;
	real[real][2] vectors = create_vectors(list1, list2, threshold);
	foreach (mz, intensity; vectors[0])
	{
		consensus_peaks[mz] = (
				(intensity * weight1 + 
				 vectors[1][mz] * weight2) / 
				total);
	}
	return consensus_peaks;
}
unittest
{
	real[real] first = [
		100.1: 10000,
		100.2: 10000,
		200.1: 15000,
		300.1: 0
	];
	ulong first_weight = 3;
	real[real] second = [
		100.1: 0,
		200.1: 15000,
		300.1: 10000
	];
	ulong second_weight = 2;
	real[real] expected = [
		100.1: 12000,
		200.1: 15000,
		300.1: 4000
	];
	double threshold = 0.1;
	real[real] output = combine_peak_lists(first, first_weight, 
			second, second_weight, threshold);
	assert(output == expected);
}
