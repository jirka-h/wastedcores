#!/bin/bash
shopt -s extglob

COMPILER=hhvm
#INPUT=/tmpfs/group-imbalance.txt

usage()
{
  echo "usage: `basename $0` FILE"
  echo "       FILE was created by running cat /proc/sched_profiler"
  echo "       with sched_profiler.ko kernel module loaded"
  echo "       FILE can be compressed with xz"
}

if [ "$#" -ne 1 ]
then
  usage
  exit 1
fi

INPUT="$1"

if [[ ! -r "${INPUT}" ]] || [[ ! -f "${INPUT}" ]] ; then
  echo "\"${INPUT}\" is not readable"
  usage
  exit 1
fi

FILETYPE=$(file -b "${INPUT}")
case $FILETYPE in 
XZ*)     BIN="xzcat";; 
*ASCII*) BIN= "cat";; 
*)       echo "Unknown filetype ${FILETYPE}"; usage; exit1;;
esac

generate_sched_profiler_graphs_all_parallel()
{
    I=0

    START_PADDED=`printf "%03d" $START`
    FILE_BASENAME=$(basename $INPUT)
    FILE_ROOT=${FILE_BASENAME%.*}

    ${BIN} $INPUT |                                                               \
        ${COMPILER}                                                            \
        ./parse_rows_sched_profiler.php                                        \
        output/${5}_standard.png                                               \
        $3 60500 -1 0 standard $1 $2 $4 &

    ${BIN} $INPUT |                                                               \
        ${COMPILER}                                                            \
        ./parse_rows_sched_profiler.php                                        \
        output/${5}_load.png                                                   \
        $3 60500 -1 0 load $1 $2 $4 &
}

# Generic runqueue and load graphs
generate_sched_profiler_graphs_all_parallel 0 -1 600 nothing generic

# Considered wakeups for core zero
generate_sched_profiler_graphs_all_parallel 201 0 600 nothing wakeups

# Graph with threads movements and "overloaded wakeups"
generate_sched_profiler_graphs_all_parallel 0 -1 600 arrows arrows
generate_sched_profiler_graphs_all_parallel 0 -1 600 bad_wakeups               \
                                                     overloaded_wakeups

wait

