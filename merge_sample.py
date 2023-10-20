import sys
import os
import argparse

def read_params():
    parser = argparse.ArgumentParser(description="merge all sample's species into a table")
    # add arguments
    parser.add_argument("-i", "--input", default=".", action="store", help="Input a file dir")
    parser.add_argument("-l", "--list", action="store", help="Input a file list")
    parser.add_argument("-a", "--abundance", type=float, default=0.00, action="store", help="filter low abundance species, default: 0.00")
    parser.add_argument("-f", "--frequency", type=float, default=0.0, action="store", help="filter low frequency species, default: 0.0")
    parser.add_argument("-n", "--name", action="store", help="output file name")
    parser.add_argument("-o", "--out", default="last_result", action="store", help="last result dir, default: last_result")
    args = parser.parse_args()
    return args

def get_all_run_sp_ratio(run, run_fname, sp_ratio_map, sp_num_map):
    sp_ratio = {}
    run_f = open(run_fname, "rt")
    for line in run_f:
        line = line.rstrip().split("\t")
        species = line[0]
        ratio = line[1]
        sp_ratio[species] = ratio
        if species not in sp_num_map:
            sp_num_map[species] = 1
        else:
            sp_num_map[species] += 1
    sp_ratio_map[run] = sp_ratio
    run_f.close()


if __name__=="__main__":
    args = read_params()
    input_dir = args.input # input file dir
    run_fname = args.list  # run list file name
    abun = args.abundance  # abundnace threshold
    freq = args.frequency  # frequency threshold
    m_name = args.name     # out file name
    out_dir = args.out   # out dir

    sp_ratio_dict = {}     # species:ratio
    sp_num_dict = {}       # run:{species:ratio}
    num = 0                # stat run number
    run_li = open(run_fname, "rt")
    for run in run_li:
        run = run.rstrip()
        run_fname = input_dir + "/" + run + "_profile.txt"
        get_all_run_sp_ratio(run, run_fname, sp_ratio_dict, sp_num_dict)
        num += 1
    run_li.close()

    last_sp_li = []
    save_num = num*freq
    for sp, num in sp_num_dict.items():
        if num >= save_num:
            last_sp_li.append(sp)

    # write matrix into disk
    if not os.path.exists(out_dir):
        os.mkdir(out_dir)
    out_fname = out_dir + "/" + m_name + ".txt"
    out_f = open(out_fname, 'w')
    out_f.write("run_accession" + '\t' + '\t'.join(last_sp_li) + '\n')
    for run, sp_ratio_map in sp_ratio_dict.items():
        out_f.write(run)
        for sp in last_sp_li:
            if sp in sp_ratio_map:
                ratio = sp_ratio_map[sp]
                if float(ratio) >= abun:
                    out_f.write('\t' + ratio)
                else:
                    out_f.write('\t' + "0.0000")
            else:
                out_f.write('\t' + "0.0000")
        out_f.write('\n')
    out_f.close()

    res_dir = args.out
    out_name = args.name
    if not os.path.exists(res_dir):
        os.mkdir(res_dir)
    out_file = open(res_dir + "/" + out_name + ".txt", "w")
    all_species = composite_dict.keys()
    out_file.write("run_accession" + '\t' + "\t".join(all_species) + '\n')

    for i in range(len(f_name_li)):
        out_file.write(f_name_li[i])
        for j in composite_dict.keys():
            out_file.write('\t' + str(composite_dict[j][i]))
        out_file.write('\n')

    out_file.close()
