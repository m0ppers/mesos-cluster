#include <iostream>
#include <iomanip>
#include <unistd.h>
#include <sstream>
#include <sys/sysinfo.h>
#include <sys/statvfs.h>

using namespace std;

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
  
  long memory; 
  struct sysinfo info;
  if (sysinfo(&info) != 0) {
    cerr << "Couldn't get sysinfo" << endl;
    return -2;
  }
  memory = info.freeram * info.mem_unit / 1024 / 1024;
  
  long cpus = sysconf(_SC_NPROCESSORS_ONLN);

  if (cpus < 0) {
    cerr << "Couldn't get cpus" << endl;
    return -3;
  }

  cout << fixed << setprecision(2) << "cpus:" << (float)cpus/(float)num_slaves << ";mem:" << memory/num_slaves << ";disk:" << diskfree/num_slaves << endl;
}
