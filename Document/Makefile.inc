#
#
#

doc_dir		= $(project_dir)/Document
resource_dir	= $(project_dir)/Resource
types_dir	= $(resource_dir)/Library/types

m4_cmd	= m4 --prefix-builtins \
	     --include=$(types_dir)

