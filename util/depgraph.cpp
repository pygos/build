#include <sys/types.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include <unordered_set>
#include <iostream>
#include <map>

struct meta_pkg_t {
	meta_pkg_t(const char *pkgname) : name(pkgname), marked(false) {
	}

	void markPackage() {
		if (!marked) {
			marked = true;

			for (auto &dep : depends)
				dep->markPackage();
		}
	}

	std::string name;
	bool marked;

	std::unordered_set<meta_pkg_t *> depends;
};


static std::map<std::string, meta_pkg_t *> package_by_name;
static std::map<std::string, meta_pkg_t *> package_provides;


static void handle_provides(const char *meta, const char *subpkg)
{
	meta_pkg_t *pkg;

	if (package_by_name.find(meta) == package_by_name.end())
		package_by_name[meta] = new meta_pkg_t(meta);

	package_provides[subpkg] = package_by_name[meta];
}

static void handle_depends(const char *meta, const char *dependency)
{
	auto it = package_provides.find(dependency);

	if (it == package_provides.end()) {
		std::cerr << "nothing provides '" << dependency;
		std::cerr << "', required by '" << meta << "'" << std::endl;
		exit(EXIT_FAILURE);
	}

	package_by_name[meta]->depends.insert(it->second);
}


typedef void (*line_handler_t)(const char *lhs, const char *rhs);

static int foreach_line(const char *filename, line_handler_t cb)
{
	FILE *f = fopen(filename, "r");

	for (;;) {
		char *line = NULL;
		size_t n = 0;
		ssize_t ret;

		errno = 0;
		ret = getline(&line, &n, f);

		if (ret < 0) {
			if (errno == 0) {
				free(line);
				break;
			}
			perror(filename);
			free(line);
			fclose(f);
			return -1;
		}

		char *rhs = strchr(line, ',');
		if (rhs == NULL) {
			free(line);
			continue;
		}

		*(rhs++) = '\0';

		char *ptr = rhs;
		while (*ptr != '\0' && !isspace(*ptr))
			++ptr;
		*ptr = '\0';

		cb(line, rhs);
		free(line);
	}

	fclose(f);
	return 0;
}

int main(int argc, char **argv)
{
	if (argc < 4) {
		std::cerr << "usage: depgraph <providerlist> <dependencylist>";
		std::cerr << " PACKAGES..." << std::endl;
		return EXIT_FAILURE;
	}

	foreach_line(argv[1], handle_provides);
	foreach_line(argv[2], handle_depends);

	// recursively mark packages that we actually need to build
	for (int i = 3; i < argc; ++i) {
		auto it = package_provides.find(argv[i]);

		if (it == package_provides.end()) {
			std::cerr << "nothing provides '" << argv[i] << "'";
			std::cerr << std::endl;
			return EXIT_FAILURE;
		}

		it->second->markPackage();
	}

	// assemble a set of only those packages
	std::unordered_set<meta_pkg_t *> pkglist;

	for (auto &it : package_by_name) {
		if (it.second->marked) {
			pkglist.insert(it.second);
		} else {
			delete it.second;
		}
	}

	package_provides.clear();
	package_by_name.clear();

	// output set in topological order
	while (pkglist.size() > 0) {
		meta_pkg_t *pkg = NULL;

		for (auto &it : pkglist) {
			if (it->depends.size() == 0) {
				pkg = it;
				break;
			}
		}

		if (pkg == NULL) {
			std::cerr << "dependency graph is cyclic!";
			std::cerr << std::endl;
			return EXIT_FAILURE;
		}

		for (auto &it : pkglist)
			it->depends.erase(pkg);

		pkglist.erase(pkg);

		std::cout << pkg->name << std::endl;
		delete pkg;
	}

	return EXIT_SUCCESS;
}
