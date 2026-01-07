#
# Makefile
#
CC = aarch64-linux-gcc
LVGL_DIR_NAME ?= lvgl
LVGL_DIR ?= ${shell pwd}

# 【修改1】定义构建目录
BUILD_DIR = build

CFLAGS ?= -O3 -g0 -I$(LVGL_DIR)/ -Wall -Wshadow -Wundef -Wmissing-prototypes -Wno-discarded-qualifiers -Wall -Wextra -Wno-unused-function -Wno-error=strict-prototypes -Wpointer-arith -fno-strict-aliasing -Wno-error=cpp -Wuninitialized -Wmaybe-uninitialized -Wno-unused-parameter -Wno-missing-field-initializers -Wtype-limits -Wsizeof-pointer-memaccess -Wno-format-nonliteral -Wno-cast-qual -Wunreachable-code -Wno-switch-default -Wreturn-type -Wmultichar -Wformat-security -Wno-ignored-qualifiers -Wno-error=pedantic -Wno-sign-compare -Wno-error=missing-prototypes -Wdouble-promotion -Wclobbered -Wdeprecated -Wempty-body -Wtype-limits -Wshift-negative-value -Wstack-usage=2048 -Wno-unused-value -Wno-unused-parameter -Wno-missing-field-initializers -Wuninitialized -Wmaybe-uninitialized -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers -Wtype-limits -Wsizeof-pointer-memaccess -Wno-format-nonliteral -Wpointer-arith -Wno-cast-qual -Wmissing-prototypes -Wunreachable-code -Wno-switch-default -Wreturn-type -Wmultichar -Wno-discarded-qualifiers -Wformat-security -Wno-ignored-qualifiers -Wno-sign-compare
LDFLAGS ?= -lm
BIN = demo

#Collect the files to compile
MAINSRC = ./main.c

include $(LVGL_DIR)/lvgl/lvgl.mk
include $(LVGL_DIR)/lv_drivers/lv_drivers.mk

# 1. 递归查找 ui 目录及其子目录下所有的 .c 文件
CSRCS += $(shell find $(LVGL_DIR)/ui -name "*.c")

# 2. 添加 ui 目录到头文件路径
# (SLS 生成的代码通常只需要 -Iui 即可，它内部引用子目录是相对路径)
CFLAGS += -I$(LVGL_DIR)/ui
# 【上次的修改】加入 my_ui 源文件
CSRCS += $(wildcard $(LVGL_DIR)/my_ui/*.c)

OBJEXT ?= .o

# 【修改2】给所有对象文件加上 build/ 前缀
AOBJS = $(addprefix $(BUILD_DIR)/, $(ASRCS:.S=$(OBJEXT)))
COBJS = $(addprefix $(BUILD_DIR)/, $(CSRCS:.c=$(OBJEXT)))
MAINOBJ = $(addprefix $(BUILD_DIR)/, $(MAINSRC:.c=$(OBJEXT)))

SRCS = $(ASRCS) $(CSRCS) $(MAINSRC)
OBJS = $(AOBJS) $(COBJS)

all: default

# 【修改3】更新编译规则：自动创建目录
$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	@$(CC)  $(CFLAGS) -c $< -o $@
	@echo "CC $<"

default: $(AOBJS) $(COBJS) $(MAINOBJ)
	$(CC) -o $(BIN) $(MAINOBJ) $(AOBJS) $(COBJS) $(LDFLAGS)

# 【修改4】清理时直接删除 build 目录
clean: 
	rm -f $(BIN)
	rm -rf $(BUILD_DIR)

# --- 下面是你的 ADB 部署脚本 (保持不变) ---
ADB = /mnt/d/platform-tools/adb.exe
WIN_TEMP = /mnt/d/Linux/demo_bin
WIN_SOURCE = D:\\Linux\\demo_bin

deploy: $(BIN)
	@echo "0. [Syncing] Ensuring binary is ready..."
	@sync  # 1. 强制将编译好的文件写入磁盘

	@echo "1. [Copying] Copying to Windows temp..."
	@cp $(BIN) $(WIN_TEMP)
	@sync  # 2. 再次强制同步，确保复制完成
	@sleep 2  # 3. 【关键】强制等待2秒，给Windows文件系统一点反应时间

	@echo "2. [Pushing] Pushing to board..."
	# 杀掉旧进程
	-@$(ADB) shell "killall -9 demo_run"
	
	# 推送
	@$(ADB) push $(WIN_SOURCE) /userdata/demo_run

	@echo "3. [Running] Granting permissions and Starting..."
	@$(ADB) shell "chmod +x /userdata/demo_run && /userdata/demo_run &"