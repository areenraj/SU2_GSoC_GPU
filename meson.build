
project('SU2', 'c', 'cpp',
        version: '8.2.0 "Harrier"',
        meson_version: '>=1.8.2',
        license: 'LGPL2',
        default_options: ['buildtype=release',
                          'warning_level=0',
                          'b_ndebug=true',
                          'c_std=c99',
                          'cpp_std=c++17'])

fsmod = import('fs')
if not fsmod.exists('su2preconfig.timestamp')
  error('SU2 must be (pre-)configured with the extended Meson script (./meson.py) or with the ./preconfigure.py script in the SU2 root directory.')
endif

pymod = import('python')
python = pymod.find_installation()

if get_option('enable-cuda')
  add_languages('cuda')
  add_global_arguments('-arch=native', language : 'cuda')
endif

su2_cpp_args = []
su2_deps     = [declare_dependency(include_directories: 'externals/CLI11')]

default_warning_flags = []
if build_machine.system() != 'windows'
  if meson.get_compiler('cpp').get_id() != 'intel'
    default_warning_flags += ['-Wno-empty-body']
  endif
  desired_warnings = ['-Wno-ignored-qualifiers',
                      '-Wno-unused-parameter',
                      '-Wno-deprecated-declarations',
                      '-Wno-error=cast-function-type',
                      '-Wno-cast-function-type',
                      '-Wno-error=stringop-truncation',
                      '-Wno-stringop-truncation',
                      '-Wno-error=missing-field-initializers',
                      '-Wno-missing-field-initializers',
                      '-Wno-error=class-memaccess',
                      '-Wno-class-memaccess']
  foreach flag : desired_warnings
    if meson.get_compiler('cpp').has_argument(flag)
      default_warning_flags += flag
    endif
  endforeach

  if get_option('enable-autodiff') or get_option('enable-directdiff')
    default_warning_flags += ['-Wno-non-virtual-dtor']
  endif
endif

# Handle assertions: default is b_ndebug=true (assertions disabled)
# but for debug builds, we want to enable assertions
if get_option('buildtype') == 'debug'
  # Undefine NDEBUG
  su2_cpp_args += '-UNDEBUG'
endif

# meson script path
script_path = meson.project_source_root() / 'meson_scripts'

# mpi flag
mpi = false

# If custom mpi mode is enabled, include and library pathes for MPI have to be set manually to env variables
if get_option('custom-mpi')
  mpi_dep = []
  mpi = true
# Otherwise they are automatically determined
else
  mpi_dep = [dependency('mpi', language:'c', required : get_option('with-mpi')),
             dependency('mpi', language:'cpp', required : get_option('with-mpi'))]
  if mpi_dep[0].found() or mpi_dep[1].found()
    mpi = true
  endif
endif

# OpenMP
omp = get_option('with-omp')

if omp
  omp_dep = dependency('openmp', language:'cpp')
endif

if get_option('enable-autodiff') or get_option('enable-directdiff')
  codi_dep = [declare_dependency(include_directories: 'externals/codi/include')]
  codi_rev_args = ['-DCODI_REVERSE_TYPE']
  codi_for_args = ['-DCODI_FORWARD_TYPE']

  if get_option('debug')
    codi_rev_args += '-DCODI_EnableAssert'
    codi_for_args += '-DCODI_EnableAssert'
  endif
endif

if get_option('enable-autodiff') and not omp
  if get_option('codi-tape') == 'JacobianLinear'
    codi_rev_args += '-DCODI_JACOBIAN_LINEAR_TAPE'
  elif get_option('codi-tape') == 'JacobianReuse'
    codi_rev_args += '-DCODI_JACOBIAN_REUSE_TAPE'
  elif get_option('codi-tape') == 'JacobianMultiUse'
    codi_rev_args += '-DCODI_JACOBIAN_MULTIUSE_TAPE'
  elif get_option('codi-tape') == 'PrimalLinear'
    codi_rev_args += '-DCODI_PRIMAL_LINEAR_TAPE'
  elif get_option('codi-tape') == 'PrimalReuse'
    codi_rev_args += '-DCODI_PRIMAL_REUSE_TAPE'
  elif get_option('codi-tape') == 'PrimalMultiUse'
    codi_rev_args += '-DCODI_PRIMAL_MULTIUSE_TAPE'
  elif get_option('codi-tape') == 'Tag'
    codi_rev_args += '-DCODI_TAG_TAPE'
  else
    error('Invalid CoDiPack tape choice @0@'.format(get_option('codi-tape')))
  endif

  if get_option('codi-tape') != 'JacobianLinear'
    warning('The tape choice @0@ is not tested regularly in SU2'.format(get_option('codi-tape')))
  endif
endif

# add cgns library
if get_option('enable-cgns')
  subdir('externals/cgns')
  su2_deps     += cgns_dep
  su2_cpp_args += '-DHAVE_CGNS'
endif

# check for mixed precision floating point arithmetic
if get_option('enable-mixedprec')
  su2_cpp_args += '-DUSE_MIXED_PRECISION'
endif

# check if MPI dependencies are found and add them
if mpi

  # add MPI dependency
  su2_deps += mpi_dep
  su2_cpp_args += '-DHAVE_MPI'

  # compile metis
  subdir('externals/metis')

  # add metis dependency
  su2_deps     += metis_dep
  su2_cpp_args += '-DHAVE_METIS'

  # compile parmetis
  subdir('externals/parmetis')

  # add parmetis dependency
  su2_deps     += parmetis_dep
  su2_cpp_args += '-DHAVE_PARMETIS'

  # add medi dependency
  if get_option('enable-autodiff') or get_option('enable-directdiff')
    codi_dep += declare_dependency(include_directories: ['externals/medi/include', 'externals/medi/src'])
  endif
endif

if omp
  # add OpenMP dependency
  su2_deps += omp_dep

  # add opdi dependency
  if get_option('enable-autodiff')
    codi_dep += declare_dependency(include_directories: 'externals/opdi/include')
    codi_rev_args += '-DCODI_EnableOpenMP'
    codi_rev_args += '-DCODI_EnableOpDiLib'

    if get_option('opdi-backend') == 'macro'
      su2_cpp_args += '-DFORCE_OPDI_MACRO_BACKEND'
    elif get_option('opdi-backend') == 'ompt'
      su2_cpp_args += '-DFORCE_OPDI_OMPT_BACKEND'
    endif

    if get_option('opdi-shared-read-opt') == false
      su2_cpp_args += '-DOPDI_VARIABLE_ADJOINT_ACCESS_MODE=0'
    endif
  endif
endif

if get_option('enable-tecio')
  subdir('externals/tecio')
endif

# PaStiX
if get_option('enable-pastix')
  assert(mpi,
         'PaStiX support requires MPI')
  assert(get_option('enable-mkl') or get_option('enable-openblas'),
         'PaStiX support requires either mkl or openblas')

  su2_cpp_args += '-DHAVE_PASTIX'

  pastix_dep = dependency('pastix', required: false)

  if not pastix_dep.found()
    pastix_root = get_option('pastix_root')+'/install'
    scotch_root = get_option('scotch_root')+'/lib'
    pastix_dep  = declare_dependency(include_directories: pastix_root,
                                    link_args: [ '-L../'+pastix_root, '-L../'+scotch_root,
                                    '-lpastix', '-lscotch', '-lptscotch', '-lptscotcherr',
                                    '-lm', '-lrt', '-lpthread'])
  endif
  su2_deps += pastix_dep
endif

# CUDA dependencies
if get_option('enable-cuda')
  su2_cpp_args += '-DHAVE_CUDA'
  gpu_dep = dependency('cuda', version : '>=10', modules : ['cudart'])
  su2_deps += gpu_dep
endif

# blas-type dependencies
if get_option('enable-mkl')

  su2_cpp_args += '-DHAVE_MKL'

  # the following mkl name matches the linked libs in manual dependency
  # see https://software.intel.com/en-us/articles/intel-math-kernel-library-intel-mkl-and-pkg-config-tool
  # should probably switch to iomp if Intel OpenMP is used
  mkl_dep = dependency('mkl-static-lp64-seq', required: false)

  if not mkl_dep.found()
    mkl_root = get_option('mkl_root')
    mkl_dep = declare_dependency(include_directories: mkl_root+'/include', compile_args: '-m64',
      link_args: ['-L'+mkl_root+'/lib/intel64','-lmkl_intel_lp64','-lmkl_sequential','-lmkl_core','-lpthread','-lm','-ldl'])
  endif
  su2_deps += mkl_dep

elif get_option('enable-openblas')

  su2_cpp_args += '-DHAVE_BLAS'
  su2_cpp_args += '-DHAVE_LAPACK'
  blas_dep = dependency(get_option('blas-name'))
  su2_deps += blas_dep

endif

if get_option('enable-librom')

   assert(get_option('librom_root')!='',
       'Must specify librom folder (-Dlibrom_root=path/to/libROM)')

   su2_cpp_args += '-DHAVE_LIBROM'

   librom_root = get_option('librom_root')
   librom_dep = declare_dependency(include_directories: librom_root+'/lib',
                                   link_args: ['-L'+librom_root+'/build', '-lROM'])

   su2_deps += librom_dep

endif

mel_dep = declare_dependency(include_directories: 'externals/mel')
su2_deps += mel_dep

extra_deps = get_option('extra-deps').split(',')
foreach dep : extra_deps
  if dep != ''
    su2_deps += dependency(dep)
  endif
endforeach

catch2_dep = declare_dependency(include_directories: 'externals/catch2/')

if get_option('enable-mpp')
  cmake = import('cmake')
  cmake_opts = cmake.subproject_options()
  cmake_opts.set_override_option('warning_level', '0')
  cmake_opts.add_cmake_defines({
    'CMAKE_MAKE_PROGRAM': join_paths(meson.project_source_root(), 'ninja'),
    'CMAKE_POSITION_INDEPENDENT_CODE': 'ON'
  })
  cmake_opts.set_install(get_option('install-mpp'))
  mpp_subproj = cmake.subproject('Mutationpp', options: cmake_opts)
  mpp_dep = mpp_subproj.dependency('mutation++')
  su2_deps     += mpp_dep
  su2_cpp_args += '-DHAVE_MPP'

  if get_option('install-mpp')
    py = find_program('python3', 'python')
    p = run_command(py, 'SU2_PY/copy_directory.py', 'subprojects/Mutationpp/data', join_paths(get_option('prefix'), 'mpp-data'))
    if p.returncode() != 0
      error(p.stderr())
    endif
  endif
endif

if get_option('enable-coolprop')
  if build_machine.cpu_family() == 'x86' or build_machine.cpu_family() == 'x86_64'
    cmake = import('cmake')
    cmake_opts = cmake.subproject_options()
    cmake_opts.set_override_option('warning_level', '0')
    cmake_opts.add_cmake_defines({
      'COOLPROP_STATIC_LIBRARY': true,
      'CMAKE_MAKE_PROGRAM': join_paths(meson.project_source_root(), 'ninja'),
      'CMAKE_POSITION_INDEPENDENT_CODE': 'ON'
    })
    coolprop_subproj = cmake.subproject('CoolProp', options: cmake_opts)
    coolprop_dep = coolprop_subproj.dependency('CoolProp')
    su2_deps     += coolprop_dep
    su2_cpp_args += '-DHAVE_COOLPROP'
  else
    message('WARNING: CPU is not x86, skipping CoolProp dependency.')
  endif
endif

if get_option('enable-mlpcpp')
  su2_cpp_args += '-DHAVE_MLPCPP'
endif

if omp and get_option('enable-autodiff')
  py = find_program('python3','python')
  p = run_command(py, 'externals/opdi/syntax/check.py', 'su2omp.syntax.json', 'Common', 'SU2_CFD', '-p', '*.hpp', '*.cpp', '*.inl', '-r', '-q')
  if p.returncode() != 0
    error(p.stdout())
  endif
endif

# compile common library
subdir('Common/src')
# compile SU2_CFD executable
subdir('SU2_CFD/src')
# compile SU2_DEF executable
subdir('SU2_DEF/src')
# compile SU2_DOT executable
subdir('SU2_DOT/src')
# compile SU2_GEO executable
subdir('SU2_GEO/src')
# compile SU2_SOL executable
subdir('SU2_SOL/src')
# install python scripts
subdir('SU2_PY')
# unit tests
subdir('UnitTests')

if get_option('enable-pywrapper')
  subdir('SU2_PY/pySU2')
endif

message('''-------------------------------------------------------------------------
         |    ___ _   _ ___                                                      |
         |   / __| | | |_  )   Release 8.2.0 "Harrier"                           |
         |   \__ \ |_| |/ /                                                      |
         |   |___/\___//___|   Meson Configuration Summary                       |
         |                                                                       |
         -------------------------------------------------------------------------

         Option          Value
         ---------------------
         TecIO:          @2@
         CGNS:           @3@
         AD (reverse):   @4@
         AD (forward):   @5@
         Python Wrapper: @6@
         Intel-MKL:      @7@
         OpenBlas:       @8@
         PaStiX:         @9@
         Mixed Float:    @10@
         libROM:         @11@
         CoolProp:       @12@
         MLPCpp:         @13@

         Please be sure to add the $SU2_HOME and $SU2_RUN environment variables,
         and update your $PATH (and $PYTHONPATH if applicable) with $SU2_RUN

         Based on the input to this configuration, add these lines to your .bashrc file:

         export SU2_RUN=@0@
         export SU2_HOME=@1@
         export PATH=$PATH:$SU2_RUN
         export PYTHONPATH=$PYTHONPATH:$SU2_RUN

         Use './ninja -C @14@ install' to compile and install SU2
'''.format(get_option('prefix')+'/bin', meson.project_source_root(), get_option('enable-tecio'), get_option('enable-cgns'),
           get_option('enable-autodiff'), get_option('enable-directdiff'), get_option('enable-pywrapper'), get_option('enable-mkl'),
           get_option('enable-openblas'), get_option('enable-pastix'), get_option('enable-mixedprec'), get_option('enable-librom'), get_option('enable-coolprop'),
           get_option('enable-mlpcpp'), meson.project_build_root().startswith(meson.project_source_root()) ? meson.project_build_root().split('/')[-1] : meson.project_build_root()))

if get_option('enable-mpp')
  if get_option('install-mpp')
    message(''' To run SU2 with Mutation++ library, add these lines to your .bashrc file:

            export MPP_DATA_DIRECTORY=$SU2_RUN/../mpp-data
            export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SU2_RUN/../lib

            ''')
  else
    message(''' To run SU2 with Mutation++ library, add these lines to your .bashrc file:

            export MPP_DATA_DIRECTORY=$SU2_HOME/subprojects/Mutationpp/data
            export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SU2_HOME/<build_dir>/subprojects/Mutationpp

            ''')
  endif
endif

if get_option('enable-librom')
  message(''' To run SU2 with libROM library, add this line to your .bashrc file:

          export LD_LIBRARY_PATH=@0@/build/:$LD_LIBRARY_PATH

          '''.format(get_option('librom_root')))

endif

if get_option('enable-pywrapper') and get_option('enable-cgns') and not get_option('static-cgns-deps')
  message(''' WARNING: If compilation fails with a message regarding "attempted static link of dynamic object", reconfigure with option -Dstatic-cgns-deps=true.''')
endif
