#include <iostream>
#include <fstream>
#include <iomanip>
#include <unistd.h>
#include <sstream>
#include <sys/sysinfo.h>
#include <sys/statvfs.h>

using namespace std;

unsigned int get_memory() {
  unsigned long long memory = 0;
  ifstream mem_cgroup;
  mem_cgroup.open("/sys/fs/cgroup/memory/memory.limit_in_bytes", ifstream::in);
  
  if (mem_cgroup) {
    mem_cgroup >> memory;
  }
  // mop: the number seems to be some magic INFINITY indicator...check for available memory traditionally in that case 
  if (memory == 0 || memory == 0x7FFFFFFFFFFFF000) {
    struct sysinfo info;
    if (sysinfo(&info) != 0) {
      return 0;
    }
    memory = info.totalram * info.mem_unit;
  }
  return memory / 1024 / 1024;
}

int main(int argc, char** argv) {
  if (argc < 3) {
    cerr << "Usage: " << argv[0] << " <slave-count> <slave-directory>" << endl;
    return 99;
  }

  istringstream ss(argv[1]);
  int num_slaves;
  if (!(ss >> num_slaves)) {
    cerr << "Invalid number " << argv[1] << endl;
  }
  
  if (num_slaves <= 0) {
    cerr << "Slave count must be >0 (Got " << num_slaves << ")" << endl;  
    return 1;
  }

  unsigned long long diskfree;
  struct statvfs stat;
  if (statvfs(argv[2], &stat) != 0) {
    cerr << "Couldn't get diskfree. Maybe invalid path?" << endl;
    return -1;
  }
  diskfree = stat.f_bsize * stat.f_bfree / 1024 / 1024;
  
  unsigned int memory = get_memory();

  if (memory == 0) {
    cerr << "Couldn't determine memory" << endl;
    return -2;
  }
  
  long cpus = sysconf(_SC_NPROCESSORS_ONLN);

  if (cpus < 0) {
    cerr << "Couldn't get cpus" << endl;
    return -3;
  }

  cout << fixed << setprecision(2) << "cpus:" << (float)cpus/(float)num_slaves << ";mem:" << memory/num_slaves << ";disk:" << diskfree/num_slaves << endl;
}
