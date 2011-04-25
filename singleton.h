#define MAKE_SINGLETON(class_name, method_name) \
static class_name *shared ## class_name; \
+ (void)initialize { \
	if (self == [class_name class]) \
		shared ## class_name = [[super allocWithZone:NULL] init]; \
} \
+ (class_name *)method_name { \
	return shared ## class_name; \
}
