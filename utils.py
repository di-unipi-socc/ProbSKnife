import sys
import os
import subprocess
import pandas as pd
from parse import *

class Partitioning:
    def __init__(self, pstring):
        self.domains = []
        for domains in findall('[{}]', pstring):
            for d in domains:
                d=d.replace(',',' ')
                sws = d.split()
                sws.sort()
                self.domains.append(tuple(sws))
        self.domains=tuple(self.domains)

    def __str__(self):
        return str(self.domains).replace('\'','').replace(',)',')').replace('(','[').replace(')',']')    

    def __eq__(self, other):
        if isinstance(other, Partitioning):
            if(not len(self.domains)==len(other.domains)):
                return False
            for d in self.domains:
                if(not d in other.domains):
                    return False
            return True
        return False

    def __ne__(self, obj):
        return not self == obj
    
    def __lt__(self, other):
        return len(self.domains) < len(other.domains)
    
    def __hash__(self):
        return hash(self.domains)

def checkArgs():
    usage = 'Usage: "main.py [-d DLIMIT] [-k CHANGELIMIT] [-t] [-l]"\n\tDLIMIT\t\tan integer\n\tCHANGELIMIT\tan integer\n\t-t\t\tshow tables\n\t-l\t\tshow partitioning labels (impacts on groupby in table)'
    args = sys.argv[1:]

    #Without limit the query as 'inf' as upper bound for partioning dimension
    Dlimit='inf'
    #Check for domain limit argument
    if('-d' in args):
        i_ind=args.index('-d')
        if(not len(args)>i_ind+1):
            print(usage)
            exit()
        Dlimit = args[i_ind+1]
        if(not Dlimit.isdigit()):
            print(usage)
            exit()
    #Check for number of changes limit argument
    K = 'inf'
    if('-k' in args):
        i_ind=args.index('-k')
        if(not len(args)>i_ind+1):
            print(usage)
            exit()
        K = args[i_ind+1]
        if(not K.isdigit()):
            print(usage)
            exit()
    #Check for show tables argument and labelling of partitionings argument
    tables = False
    labellingsP = False
    if('-t' in args):
        tables = True
    if('-l' in args):
        labellingsP = True
    
    return (Dlimit,K,tables,labellingsP)

def queryLabellings(queryString,K):
    ######## FIRST QUERY
    #Query string for labelling probabilities
    
    #Write query string in file query.pl
    with open('query.pl', 'w') as f:
        f.write(queryString)

    #Running problog program with query
    output1 = subprocess.run(['python', '-m','problog','mainPr.pl','query.pl','--combine'], stdout=subprocess.PIPE)

    #removing the query file
    os.remove('query.pl')

    #Parse first query output
    format_output1 = 'labellingK('+K+',{},{:d}):{:f}'

    s=str(output1.stdout,'utf-8')
    s=s.replace('\t', '')
    s=s.replace(' ', '')
    lines = s.splitlines()

    labellings = []
    for line in lines :
        parsed = parse(format_output1, line)
        if(parsed is None):
            #parsing problem, probably output error from problog
            print(s)
            print('Something went wrong, check the Problog model.')
            exit()
        if(parsed[1]==0):
            Labelling0 = ((parsed[0],parsed[2]))
        else:
            labellings.append((parsed[0],parsed[2]))

    #Calculating change labelling probabilities
    denominator = 0.0
    for (l,p) in labellings:
        denominator+=p
    denominator=round(denominator,11)
    labellingString =''
    sump=0.0
    for (l,p) in labellings:
        pl = round(p * (1 - Labelling0[1]) / denominator,11)
        sump+=pl
        labellingString+=str(pl)+'::labelling0L('+l+').\n'
    #String with probabilistic predicates for writing to file
    labellingString += str(1-sump)+'::labelling0L('+Labelling0[0]+').\n'

    return (labellingString,Labelling0[0])

def queryAllPartitionings(queryString,StartingLabelling,Dlimit):
    with open('query.pl', 'w') as f:
        f.write(queryString)
    
    output = subprocess.run(['python', '-m','problog','mainPr.pl','query.pl','--combine'], stdout=subprocess.PIPE)
    
    os.remove('query.pl')
    format_string_output = ('sKnife(smallExample,'+StartingLabelling+','+Dlimit+',{}):{}').replace(' ','')

    s=str(output.stdout,'utf-8')
    s=s.replace('\t', '')
    s=s.replace(' ', '')
    lines = s.splitlines()
    partitionings = []
    for line in lines:
        parsed = parse(format_string_output, line)
        if(parsed is None):
            #parsing problem, probably output error from problog
            print(s)
            print('Something went wrong, check the Problog model.')
            exit()
        partitionings.append(parsed[0])
    return partitionings

def queryExpectedCostP(queryString,labellingString,labellingsP):
    ######## SECOND QUERY + Probabilistic predicates
    

    #Write query string in file query.pl
    with open('query.pl', 'w') as f:
        f.write(labellingString)
        f.write(queryString)

    #Running problog program with second query
    output = subprocess.run(['python', '-m','problog','mainPr.pl','query.pl','--combine'], stdout=subprocess.PIPE)
    #removing the query file
    os.remove('query.pl')

    #Second output parse
    format_string_output = '{},([{}],[{}],{:d})):{:f}'

    s=str(output.stdout,'utf-8')
    s=s.replace('\t', '')
    s=s.replace(' ', '')
    lines = s.splitlines()

    labs = []
    parts = []
    costs = []
    probs =[]
    for line in lines :
        parsed = parse(format_string_output, line)
        if(parsed is None):
            #parsing problem, probably output error from problog
            print(s)
            print('Something went wrong, check the Problog model.')
            exit()
        labs.append(parsed[1])
        #if -l is active partitionings are strings, else are Partitioning object for group by equal ones
        if(labellingsP):
            parts.append(parsed[2])
        else:
            parts.append(Partitioning(parsed[2]))
        costs.append(parsed[3])
        probs.append(parsed[4])
    return {'labs':labs, 'parts':parts, 'costs':costs, 'probs':probs}

def buildResults(parsedOutput):
    df = pd.DataFrame()
    df['labellings'] =parsedOutput['labs']
    df['partitionings']= parsedOutput['parts']
    df['costs']= parsedOutput['costs']
    df['probabilities']= parsedOutput['probs']

    #groping by labelling to find minimum partitionings
    minGroup = df.groupby(['labellings']).costs.min()
    minGroup = minGroup.reset_index()

    #filter out every row without min cost per labelling
    keys = list(minGroup.columns.values)
    i1 = df.set_index(keys).index
    i2 = minGroup.set_index(keys).index
    minFilter = df[i1.isin(i2)]


    #grouping by partitioning for the final table
    sumProb = minFilter.groupby(['partitionings','costs']).probabilities.sum()
    sumProb = sumProb.reset_index()

    #calculating expected cost considering only the minimum cost per labelling
    exp = minFilter.drop_duplicates(subset=['labellings','costs','probabilities']).reset_index()
    expectedCost = round((exp['costs'] * exp['probabilities']).sum(),12)
    #if limit is too low there are not satisfiable labellings, this is their aggregate probability
    impossible = round(exp['probabilities'].sum(),7)

    return (sumProb,expectedCost,impossible)

def printResults(Pstring,sumProb,expectedCost,impossible,verbose,labellingsP):
    Pstring = Pstring[1:-1]
    p = Partitioning(Pstring)
    ndomains = len(p.domains)
    if(labellingsP):
        printP=Pstring
    else:
        printP=str(p)
    print('Partitioning '+printP+'\t\t\tcost: ('+str(ndomains)+', '+str(expectedCost)+').\tImpossible prob: '+str(1-impossible))
    if(verbose):
        print('All the reachable partitionings with cost and probability are:')
        print(sumProb.to_string())