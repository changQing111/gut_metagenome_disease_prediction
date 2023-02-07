import sys
import os
import argparse
from decimal import Decimal

def read_params():
    parser = argparse.ArgumentParser(description="merge all sample's species into a table")
    # add arguments
    parser.add_argument("-l", "--list", action="store", help="Input a file list")
    parser.add_argument("-t", "--tmp", default="tmpout", action="store", help="tmp file dir")
    parser.add_argument("-f", "--filter", type=float, default=0.00, action="store", help="filter low abundance species")
    parser.add_argument("-o", "--out", default="filter_result", action="store", help="last result dir")
    parser.add_argument("-n", "--name", action="store", help="output file name")
    args = parser.parse_args()
    return args

def union_composite(file_name, hash_map, all_info_li):
    '''get all species'''
    comp_content = open(file_name, "rt")
    hash_map2 = {}
    for line in comp_content:
        li = line.rstrip().split("\t")
        ratio = li[0]
        species = ";".join(li[1:])
        hash_map2[species] = ratio
        if species not in hash_map:
            hash_map[species] = []
    comp_content.close()
    all_info_li.append(hash_map2)
    return hash_map

def standard(read_f, write_f, abundance):
    f = open(read_f, "rt")
    dic = {}
    for i in f:
        li = i.rstrip().split("\t")
        ratio = float(li[0])
        species = "\t".join(li[1:])
        if ratio >= abundance:
            dic[species] = ratio
    f.close()
    s = sum(dic.values())

    w_f = open(write_f, "w")
    for i in dic:
        a = dic[i]/s * 100
        a = Decimal(a).quantize(Decimal("0.0001"), rounding = "ROUND_HALF_UP")
        w_f.write(str(a) + "\t" + i + '\n')
    w_f.close()


if __name__=="__main__":
    args = read_params()
    composite_dict = {}
    all_info_li = []
    f_list = args.list
    file_o = open(f_list, "rt")
    f_name_li = []
    tmp_dir = args.tmpout
    if not os.path.exists(tmp_dir):
        os.mkdir(tmp_dir)
    abundance = args.filter
    for i in file_o:
        i = i.rstrip()
        f_name_li.append(i)
        pre_f = i + "_profile" + "/" + i
        f_name = tmp_dir + "/" + i + ".txt"
        # standard ratio
        standard(pre_f, f_name, abundance)
        composite_dict = union_composite(f_name, composite_dict, all_info_li)
    file_o.close()

    for i in composite_dict.keys():
        for j in all_info_li:
            if i in j.keys():
                composite_dict[i].append(j[i])
            else:
                composite_dict[i].append("0.0000")

    res_dir = args.out
    if not os.path.exists(res_dir):
        os.mkdir(res_dir)
    out_file = open(res_dir + "/" + sys.argv[2] + ".txt", "w")
    all_species = composite_dict.keys()
    out_file.write("run_accession" + '\t' + "\t".join(all_species) + '\n')

    for i in range(len(f_name_li)):
        out_file.write(f_name_li[i])
        for j in composite_dict.keys():
            out_file.write('\t' + str(composite_dict[j][i]))
        out_file.write('\n')

    out_file.close()
