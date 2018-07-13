Результаты:

fingerprint.c				- требуемый файл конвертации bpm в описание отпечатка в ISO/IEC 19794-2,
					  сделан из fjfxSample.c и bmptopnm.c + мои правки по мелочи.
netpbm-10.47.67_dependencies.txt	- список файлов из проекта netpbm используемых для сборки libbmptopnm.a,
patch1.diff, patch2.diff		- патчи для ещё двух файлов из netpbm используемых для сборки libbmptopnm.a,
					  изменения сделаны чтобы из c файла получить библиотечный - чтобы не 
                                          копипастить лишний код.
Makefile				- для любителей всё делать в make - запускает нижеописанные скрипты,
					  доступные варианты: make ; make check ; make clean

build.sh				- скрипт сборки, сделан для Ubuntu, на других дистрибутивах исполнятся 
					  откажется, результат сборки:
					   требуемая утилита fingerprint и сопутсвующие файлы - библиотека libbmptopnm.a,
					   библиотека fjfx и бинарь fjfxSample (используется для сравнения результатов) +
					   модификация системной конфигурации ld.config .
					   все бинари инсталируются ниже текущего каталога.

cleanup.sh				- очистка деятельности build.sh - сносятся всё что собиралось и ставилось, откатывается изменения 
					  системной конфигурации ld.config

test_resulting_binaries.sh		- автотест - этот файл запускать для проверки работы собраных бинарей, сделан для Ubuntu,
					  на других дистрибутивах исполнятся откажется.

Остальное:
test.bmp				- оригинальный bmp с отпечатком из задания
testjob.utf8.txt			- текстовик с заданием
README.utf8.txti			- этот файл.

Результаты запуска и сам финальный бинарь сделанные на моей машине можнно посмотреть в ./olli-PC-results:

bmptopgm-build-output.20180323_00:14:48.log	- вывод сборки libbmptopnm.a (команды сборки - в build.sh)
build.log					- вывод полного скрипта сборки ( ./build.sh )
cleanup.log					- вывод от запуска ./cleanup.sh (сносит результаты деятельности ./build.sh)
fingerprint-execution.log			- вывод от запуска результата тестовой задачи 
						  (./fingerprint test.bmp test.tmp 2>&1 |tee fingerpint-execution.log)
fingerprint					- бинарник собранный на моей ubuntu
fingerprint.c_compile.log			- вывод от сборки fingerprint.c (команды сборки - в build.sh)
fingerprint.ldd-info                            - вывод ldd fingerprint
make-FingerJetFXOSE.20180323_00:13:34.log	- вывод сборки библиотки сампла FingerJetFXOSE
test.log					- вывод запуска ./test_resulting_binaries.sh (проверки на корректность работы бинарей)
test.tmp					- файл отпечатка в ISO/IEC 19794-2 полученнный из ../test.bmp задания.
os-release					- /etc/os-release моей убунты
