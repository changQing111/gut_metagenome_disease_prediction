import sys
import os
from decimal import Decimal

def union_composite(file_name, hash_map, all_info_li):
    '''get all species'''
    comp_content = open(file_name, "rt")
    hash_map2 = {}
    for line in comp_content:
        li = line.rstrip().split("\t")
        ratio = li[0]
        #if float(ratio) < 0.03:
        #    continue
        species = ";".join(li[1:])
        hash_map2[species] = ratio
        if species not in hash_map:
            hash_map[species] = []
    comp_content.close()
    all_info_li.append(hash_map2)
    return hash_map

def standard(read_f, write_f):
    f = open(read_f, "rt")
    dic = {}
    for i in f:
        li = i.rstrip().split("\t")
        ratio = float(li[0])
        species = "\t".join(li[1:])
        #if ratio >= 0.01:
        dic[species] = ratio
    f.close()
    s = sum(dic.values())

    w_f = open(wrtie_f, "w")
    for i in dic:
        a = dic[i]/s * 100
        a = Decimal(a).quantize(Decimal("0.0001"), rounding = "ROUND_HALF_UP")
        w_f.write(a + "\t" + i + '\n')
    w_f.close()


if __name__=="__main__":
    composite_dict = {}
    all_info_li = []
    file_o = open(sys.argv[1], "rt")
    f_name_li = []
    tmp_dir = "tmpout"
    if not os.path.exists(tmpdir):
        os.mkdir(tmp_dir)
    for i in file_o:
        i = i.rstrip()
        f_name_li.append(i)
        #f_name = i + "_profile" + "/" + i
        pre_f = i + "_profile" + "/" + i
        f_name = tmp_dir + "/" + i + ".txt"
        # standard ratio
        standard(pre_f, f_name)
        composite_dict = union_composite(f_name, composite_dict, all_info_li)
    file_o.close()

    for i in composite_dict.keys():
        for j in all_info_li:
            if i in j.keys():
                composite_dict[i].append(j[i])
            else:
                composite_dict[i].append("0.0000")

    res_dir = "filter_result"
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
