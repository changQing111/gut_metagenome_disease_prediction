import sys
import os
import subprocess
import math
from multiprocessing import Process,Pool
import json
import pickle
import gzip
import argparse

def parse_args():
    parser = argparse.ArgumentParser(description="metagenome prfoile vector search")
    # subcommand
    subparsers = parser.add_subparsers(title='subcommand', description='index and search', dest='subcommand')
    # subcommand index
    subparser1 = subparsers.add_parser('index', help='index all vector into json')
    subparser1.add_argument('-l', '--list', help='subject vector list')
    subparser1.add_argument('-p', "--prefix", default="profile_index", help="index file prefix")
    subparser1.add_argument('-o', '--out', help='out dir')
    cpu_count = len(os.sched_getaffinity(0))
    subparser1.add_argument('-t', '--thread', type=int, default=cpu_count, help='threads number')
    # subcommand search
    subparser2 = subparsers.add_parser('search', help='search vector')
    subparser2.add_argument('-q', '--query', help='query vector list')
    subparser2.add_argument('-s', '--subject', help='subject index dir')
    subparser2.add_argument('-o', '--out', help='out dir')

    args = parser.parse_args()
    return args

def trav_profile(profile_name):
    profile = open(profile_name, "rt")
    hashmap = {}
    for line in profile:
        li = line.rstrip().split("\t")
        ratio = li[0]
        species = ";".join(li[1:])
        hashmap[species] = ratio
    profile.close()
    return hashmap

def jaccard(set1, set2):
    inter_set = set1.intersection(set2)
    union_set = set1.union(set2)
    jac = len(inter_set) / len(union_set)
    return inter_set,jac

def distance(dic1, dic2, inter_set):
    euc_dist = 0
    if len(inter_set) >= 1:
        for i in inter_set:
            euc_dist += (float(dic1[i]) - float(dic2[i]))**2
        euc_dist = math.sqrt(euc_dist)
    else:
        euc_dist = -1
    return euc_dist

def file_search(query, obj_list):
    query_profile_name = query + "_profile/" + query
    query_dic = trav_profile(query_profile_name)
    query_set = set(query_dic)
    
    search_res = open(query + "_search_" + obj_list, 'w')
    obj_file = open("../" + obj_list, "rt")
    for j in obj_file:
        obj_profile_name = j.rstrip() + "_profile/" + j.strip()
        obj_dic = trav_profile(obj_profile_name)
        obj_set = set(obj_dic)
        inter_set, jacc_s = jaccard(query_set, obj_set)
        dist = distance(query_dic, obj_dic, inter_set)
        search_res.write(query + "\t" + j.rstrip() + "\t" + str(jacc_s) + "\t" + str(dist) + "\n")
    print(".....", end="")
    search_res.close()
    obj_file.close()

def block_search(query, obj_dic, obj_num, out_dir):
    query_profile_name = query + "_profile/" + query
    query_dic = trav_profile(query_profile_name)
    query_set = set(query_dic)

    search_res = open(out_dir + "/" + query + "_search_" + str(obj_num) + ".tmp", 'w')
    for i, j in obj_dic.items():
        obj_set = set(j)
        inter_set, jacc_s = jaccard(query_set, obj_set)
        dist = distance(query_dic, j, inter_set)
        search_res.write(query + "\t" + i.rstrip() + "\t" + str(jacc_s) + "\t" + str(dist) + "\n")
    print(".....", end="")
    search_res.close()

def profile_dump(all_profile_list, dump_dic, dump_file_name):
    for i in all_profile_list:
        i = i.rstrip()
        profile_name = i + "_profile/" + i
        content = trav_profile(profile_name)
        dump_dic[i] = content
    with open(dump_file_name, "w") as f:
        json.dump(dump_dic, f)

def load_dump(file_name):
    #global search_li
    with open(file_name) as f:
        #search_li.append(json.load(f))
        return json.load(f)

def multiprocess(func, args_li):
    process_li = []
    for i in range(len(args_li)):
        p = Process(target=func, args=args_li[i])
        p.start()
        process_li.append(p)
    for p in process_li:
        p.join()

def multipool(func, args_li):
    with Pool(processes=len(args_li)) as pool:
        results = pool.map(func, args_li)
    return results

def file_block(file_name, nrow, n_block):
    all_li = []
    all_profile_li = open(file_name, "rt")
    nums = math.ceil(nrow / n_block)
    for i in range(n_block):
        li = []
        n = 0
        for j in all_profile_li:
            n += 1
            if n <= nums:
                li.append(j.rstrip())
            else:
                break
        all_li.append(li)
    return all_li
            

if __name__=="__main__":
    args = parse_args()
    out_dir = args.out
    if not os.path.exists(out_dir):
        os.mkdir(out_dir)

    if args.subcommand == "index":
        proc_num = args.thread
        index_name = args.prefix
        object_li = args.list
        output = subprocess.check_output(['wc', '-l', object_li])
        nrow = int(output.decode('utf-8').strip().split()[0])
        dump_dic = {}
        object_li = args.list
        all_profile_li = file_block(object_li, nrow, proc_num)
        args_list = [(all_profile_li[i], dump_dic, out_dir + "/" + index_name + "."+ str(i),) for i in range(len(all_profile_li))]
        multiprocess(profile_dump, args_list)
        print("Index write into disk !")

    if args.subcommand == "search":
        merge_cmd = "cat %s/*_search_*.tmp > %s/%s_search_res.txt && rm -rf %s/*_search_*.tmp"
        sort_cmd = "sort -n -r -k3 %s/%s_search_res.txt |head -n100 > %s/%s_search_res_sort.txt && rm -rf %s/%s_search_res.txt"
        query_li = args.query
        # load dump index
        obj_dir = args.subject
        index_li = os.listdir(obj_dir)
        dump_args_li = [obj_dir + "/" + i for i in index_li]
        search_li = multipool(load_dump, dump_args_li)
        print("load finised, start search!")
        # search
        query = open(query_li, "rt")
        for i in query:
            i = i.rstrip()
            args_list = [(i, search_li[j], j, out_dir, ) for j in range(len(search_li))]
            multiprocess(block_search, args_list)
            
            #for j in range(len(search_li)):
            state = subprocess.call(merge_cmd % (out_dir, out_dir, i, out_dir), shell=True)
            state = subprocess.call(sort_cmd % (out_dir, i, out_dir, i, out_dir, i), shell=True)
            
            print("")
            print(i + " search finised !")
        print("All query search finised !")
        query.close()
        
