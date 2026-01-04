/* ui_app.c */
#include "ui_app.h"
#include "lvgl/lvgl.h"

void ui_init(void)
{
    /* 这里写你的界面逻辑 */
    lv_obj_t *label = lv_label_create(lv_scr_act());
    lv_label_set_text(label, "Hello RK3566! This is from Ubuntu 18.04 build.");
    lv_obj_center(label);
}