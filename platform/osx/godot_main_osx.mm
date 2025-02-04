/*************************************************************************/
/*  godot_main_osx.mm                                                    */
/*************************************************************************/
/*                       This file is part of:                           */
/*                           GODOT ENGINE                                */
/*                      https://godotengine.org                          */
/*************************************************************************/
/* Copyright (c) 2007-2022 Juan Linietsky, Ariel Manzur.                 */
/* Copyright (c) 2014-2022 Godot Engine contributors (cf. AUTHORS.md).   */
/*                                                                       */
/* Permission is hereby granted, free of charge, to any person obtaining */
/* a copy of this software and associated documentation files (the       */
/* "Software"), to deal in the Software without restriction, including   */
/* without limitation the rights to use, copy, modify, merge, publish,   */
/* distribute, sublicense, and/or sell copies of the Software, and to    */
/* permit persons to whom the Software is furnished to do so, subject to */
/* the following conditions:                                             */
/*                                                                       */
/* The above copyright notice and this permission notice shall be        */
/* included in all copies or substantial portions of the Software.       */
/*                                                                       */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF    */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.*/
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY  */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,  */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE     */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                */
/*************************************************************************/

#include "main/main.h"

#include "os_osx.h"

#include <string.h>
#include <unistd.h>

#if defined(SANITIZERS_ENABLED)
#include <sys/resource.h>
#endif

int main(int argc, char **argv) {
#if defined(VULKAN_ENABLED)
	// MoltenVK - enable full component swizzling support.
	setenv("MVK_CONFIG_FULL_IMAGE_VIEW_SWIZZLE", "1", 1);
#endif

#if defined(SANITIZERS_ENABLED)
	// Note: Set stack size to be at least 30 MB (vs 8 MB default) to avoid overflow, address sanitizer can increase stack usage up to 3 times.
	struct rlimit stack_lim = { 0x1E00000, 0x1E00000 };
	setrlimit(RLIMIT_STACK, &stack_lim);
#endif

	int first_arg = 1;
	const char *dbg_arg = "-NSDocumentRevisionsDebugMode";
	printf("arguments\n");
	for (int i = 0; i < argc; i++) {
		if (strcmp(dbg_arg, argv[i]) == 0) {
			first_arg = i + 2;
		}
		printf("%i: %s\n", i, argv[i]);
	}

#ifdef DEBUG_ENABLED
	// Lets report the path we made current after all that.
	char cwd[4096];
	getcwd(cwd, 4096);
	printf("Current path: %s\n", cwd);
#endif

	OS_OSX os;
	Error err;

	// We must override main when testing is enabled.
	TEST_MAIN_OVERRIDE

	err = Main::setup(argv[0], argc - first_arg, &argv[first_arg]);

	if (err == ERR_HELP) { // Returned by --help and --version, so success.
		return 0;
	} else if (err != OK) {
		return 255;
	}

	if (Main::start()) {
		os.run(); // It is actually the OS that decides how to run.
	}

	Main::cleanup();

	return os.get_exit_code();
}
