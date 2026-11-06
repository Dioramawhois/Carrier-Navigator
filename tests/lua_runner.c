/* SPDX-License-Identifier: GPL-3.0-or-later */
/* Execute only explicitly supplied project-owned policies and fixtures. */
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include <stdio.h>
#include <stdlib.h>

static int run(lua_State *state, const char *path, int results) {
    FILE *file = fopen(path, "rb");
    if (!file) return 0;
    if (fseek(file, 0, SEEK_END)) { fclose(file); return 0; }
    long size = ftell(file);
    if (size < 0 || size > 1024*1024 || fseek(file, 0, SEEK_SET)) { fclose(file); return 0; }
    char *data = malloc((size_t)size + 1);
    if (!data) { fclose(file); return 0; }
    size_t count = fread(data, 1, (size_t)size, file);
    fclose(file);
    int ok = count == (size_t)size &&
        luaL_loadbufferx(state, data, count, path, "t") == LUA_OK &&
        lua_pcall(state, 0, results, 0) == LUA_OK;
    free(data);
    if (!ok) {
        const char *error = lua_tostring(state, -1);
        fprintf(stderr, "%s\n", error ? error : "Unable to read fixture");
    }
    return ok;
}
int main(int argc, char **argv) {
    if (argc != 3) return 2;
    lua_State *state = luaL_newstate();
    if (!state) return 2;
    luaL_requiref(state, "_G", luaopen_base, 1); lua_pop(state, 1);
    luaL_requiref(state, LUA_TABLIBNAME, luaopen_table, 1); lua_pop(state, 1);
    luaL_requiref(state, LUA_STRLIBNAME, luaopen_string, 1); lua_pop(state, 1);
    luaL_requiref(state, LUA_MATHLIBNAME, luaopen_math, 1); lua_pop(state, 1);
    const char *blocked[] = {"load", "loadfile", "dofile", "collectgarbage"};
    for (unsigned i = 0; i < sizeof(blocked)/sizeof(blocked[0]); ++i) {
        lua_pushnil(state); lua_setglobal(state, blocked[i]);
    }
    if (!run(state, argv[1], 1)) { lua_close(state); return 1; }
    lua_setglobal(state, "POLICY");
    int ok = run(state, argv[2], 0);
    lua_close(state);
    return ok ? 0 : 1;
}
