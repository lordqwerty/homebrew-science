class Hdf5 < Formula
  desc "File format designed to store large amounts of data"
  homepage "http://www.hdfgroup.org/HDF5"
  url "https://www.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.1/src/hdf5-1.10.1.tar.bz2"
  sha256 "9c5ce1e33d2463fb1a42dd04daacbc22104e57676e2204e3d66b1ef54b88ebf2"

  bottle do
    sha256 "cfcd0e27ff297c39b495285fc623a34b1751bdb4993beab94d86f52931bc3448" => :sierra
    sha256 "a4e677a58a57aaaa4be1dd7fd165b15272ecbf265b7acfa7b89952aea3460467" => :el_capitan
    sha256 "d9a15be0e5f7091084db292e32a469f9eaff7e3615b429c65f7fde2ef230a8f7" => :yosemite
    sha256 "a9b8f04e32dba85a013f6c1be017e336e5452091e5e29f27a2d6bc2ba965dbc5" => :x86_64_linux
  end

  deprecated_option "enable-fortran" => "with-fortran"
  deprecated_option "enable-threadsafe" => "with-threadsafe"
  deprecated_option "enable-parallel" => "with-mpi"
  deprecated_option "enable-cxx" => "with-cxx"
  deprecated_option "with-check" => "with-test"

  option "with-test", "Run build-time tests"
  option "with-threadsafe", "Trade performance for C API thread-safety (requires --without-cxx and --without-hl)"
  option "with-mpi", "Compile with parallel support (unsupported with thread-safety)"
  option "without-cxx", "Disable the C++ interface"
  option "without-hl", "Compile without high-level library"
  option "with-unsupported", "Allow unsupported combinations of configure options"
  option :cxx11

  depends_on :fortran => :optional
  depends_on "szip"
  depends_on :mpi => [:optional, :cc, :cxx, :f90]
  depends_on "zlib" unless OS.mac?

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  def install
    inreplace %w[c++/src/h5c++.in fortran/src/h5fc.in tools/src/misc/h5cc.in],
      "${libdir}/libhdf5.settings", "#{pkgshare}/libhdf5.settings"

    inreplace "src/Makefile.am", "settingsdir=$(libdir)", "settingsdir=#{pkgshare}"

    system "autoreconf", "-fiv"

    args = %W[
      --prefix=#{prefix}
      --enable-build-mode=production
      --disable-dependency-tracking
      --with-zlib=#{OS.mac? ? "/usr" : Formula["zlib"].opt_prefix}
      --with-szlib=#{Formula["szip"].opt_prefix}
      --enable-static=yes
      --enable-shared=yes
    ]
    args << "--enable-unsupported" if build.with? "unsupported"
    args << "--enable-threadsafe" << "--with-pthread=/usr" if build.with? "threadsafe"
    args << "--disable-hl" if build.without? "hl"

    if build.with?("cxx") && build.without?("mpi")
      args << "--enable-cxx"
    else
      args << "--disable-cxx"
    end

    if build.with? "fortran"
      args << "--enable-fortran"
    else
      args << "--disable-fortran"
    end

    if build.with? "mpi"
      args << "--enable-parallel"
      ENV["CC"] = ENV["MPICC"]
      ENV["CXX"] = ENV["MPICXX"]
      ENV["FC"] = ENV["MPIFC"]
    end

    system "./configure", *args
    system "make"
    system "make", "check" if build.with?("test") || build.bottle?
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<-EOS.undent
      #include <stdio.h>
      #include "hdf5.h"
      int main()
      {
        printf(\"%d.%d.%d\\n\",H5_VERS_MAJOR,H5_VERS_MINOR,H5_VERS_RELEASE);
        return 0;
      }
    EOS
    system "#{bin}/h5cc", "test.c"
    assert_equal "1.10.1", shell_output("./a.out").chomp
  end
end
