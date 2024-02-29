
zig-list:
	@zig build

run: zig-list
	@./zig-out/bin/zig-list

test:
	@zig test ./src/main.zig

clean:
	@rm -rf ./zig-out/bin/zig-list
