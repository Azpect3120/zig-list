const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;
const String: type = []const u8;

/// Task data structure
const Task = struct {
    id: u32 = 0,
    title: String,
    completed: bool = false,
};

/// Task data
const MAX: u32 = 100000;
var LEN: u32 = 0;
var tasks: [MAX]Task = undefined;
var tasks_buffer: [MAX][64]u8 = undefined;

pub fn main() !void {
    const stdin = std.io.getStdIn();
    const stdout = std.io.getStdOut();
    var buffer: [100]u8 = undefined;

    while (true) {
        try stdout.writer().print("Enter a command: ", .{});

        var line = (try readLine(stdin.reader(), &buffer)).?;

        if (startsWith(line, "exit")) {
            break;
        } else if (startsWith(line, "tasks")) {
            try printTasks();
        } else if (startsWith(line, "add")) {
            try stdout.writer().print("Task description: ", .{});
            const name = (try readLine(stdin.reader(), &tasks_buffer[LEN])).?;
            addTask(name, false);
        } else if (startsWith(line, "remove")) {
            try stdout.writer().print("Task ID: ", .{});
            line = (try readLine(stdin.reader(), &buffer)).?;
            const id: u32 = strToInt(line);
            removeTask(id);
        } else if (startsWith(line, "complete")) {
            try stdout.writer().print("Task ID: ", .{});
            line = (try readLine(stdin.reader(), &buffer)).?;
            const id: u32 = strToInt(line);
            try completeTask(id);
        } else if (startsWith(line, "incomplete")) {
            try stdout.writer().print("Task ID: ", .{});
            line = (try readLine(stdin.reader(), &buffer)).?;
            const id: u32 = strToInt(line);
            try incompleteTask(id);
        } else if (startsWith(line, "clear")) {
            try stdout.writer().print("\x1B[2J\x1B[H", .{});
        } else {
            try stdout.writer().print("Unknown command\n", .{});
        }
        buffer = undefined;
    }
}

fn readFile() void {}

fn writeFile() void {}

fn fileExists(path: String) !bool {
    _ = path;
}

/// Reads a line from a reader
fn readLine(reader: anytype, buffer: []u8) !?String {
    const line = (try reader.readUntilDelimiterOrEof(buffer, '\n')) orelse return null;
    return line;
}

/// Determine if a string starts with another string
fn startsWith(haystack: String, needle: String) bool {
    if (haystack.len < needle.len) {
        return false;
    }
    for (needle, 0..needle.len) |c, i| {
        if (c != haystack[i]) {
            return false;
        } else {}
    }
    return true;
}

/// Convert a string to a number
fn strToInt(s: []const u8) u32 {
    var result: u32 = 0;
    for (s) |c| {
        if (c >= '0' and c <= '9') {
            result = result * 10 + (c - '0');
        } else {
            return 0;
        }
    }
    return result;
}

/// Print the tasks
fn printTasks() !void {
    const stdout = std.io.getStdOut();
    if (LEN == 0) {
        std.debug.print("No tasks found\n", .{});
        return;
    }
    for (tasks[0..LEN]) |task| {
        if (task.id > 0) {
            if (task.completed) {
                try stdout.writer().print("(✓) {s} [{d}]\n", .{ task.title, task.id });
            } else {
                try stdout.writer().print("(✗) {s} [{d}]\n", .{ task.title, task.id });
            }
        }
    }
}

/// Add a task to the list
fn addTask(title: String, completed: bool) void {
    const task: Task = Task{ .id = LEN + 1, .title = title, .completed = completed };
    tasks[LEN] = task;
    LEN += 1;
}

/// Marks a task as complete
fn completeTask(id: u32) !void {
    for (0..LEN) |i| {
        if (tasks[i].id == id) {
            tasks[i].completed = true;
            return;
        }
    }
    return error.NoTaskFound;
}

/// Marks a task as incomplete
fn incompleteTask(id: u32) !void {
    for (0..LEN) |i| {
        if (tasks[i].id == id) {
            tasks[i].completed = false;
            return;
        }
    }
    return error.NoTaskFound;
}

/// Remove a task from the list
fn removeTask(id: u32) void {
    var arr: [MAX]Task = undefined;
    var index: u32 = 0;
    for (tasks[0..LEN]) |task| {
        if (task.id != id) {
            arr[index] = task;
            arr[index].id = index + 1;
            index += 1;
        }
    }
    LEN -= 1;
    tasks = arr;
}

// Unit Tests
test "Adding task" {
    tasks = undefined;
    LEN = 0;
    addTask("Task", false);
    try expect(LEN == 1);
    addTask("Task", false);
    addTask("Task", false);
    addTask("Task", false);
    try expect(LEN == 4);
}

test "Marking tasks" {
    tasks = undefined;
    LEN = 0;
    addTask("Task", false);
    try expect(tasks[0].completed == false);
    try completeTask(1);
    try expect(tasks[0].completed == true);
    try incompleteTask(1);
    try expect(tasks[0].completed == false);
}

test "Removing tasks" {
    tasks = undefined;
    LEN = 0;
    addTask("Task", false);
    try expect(LEN == 1);
    removeTask(1);
    try expect(LEN == 0);
    addTask("Task", false);
    addTask("Task", false);
    addTask("Task", false);
    removeTask(2);
    try expect(LEN == 2);
    try expect(tasks[0].id == 1);
    try expect(tasks[1].id == 2);
}

test "Stress test" {
    tasks = undefined;
    LEN = 0;
    var STRESS_MAX: u32 = 0;
    var start: i64 = undefined;
    var end: i64 = undefined;

    for (0..4) |itr| {
        switch (itr) {
            0 => {
                std.debug.print("\n10 Tasks\n", .{});
                STRESS_MAX = 10;
            },
            1 => {
                std.debug.print("\n100 Tasks\n", .{});
                STRESS_MAX = 100;
            },
            2 => {
                std.debug.print("\n1000 Tasks\n", .{});
                STRESS_MAX = 1000;
            },
            3 => {
                std.debug.print("\n10000 Tasks\n", .{});
                STRESS_MAX = 10000;
            },
            4 => {
                std.debug.print("\n100000 Tasks\n", .{});
                STRESS_MAX = 100000;
            },
            else => {},
        }

        // Create STRESS_MAX tasks
        start = std.time.milliTimestamp();
        for (0..STRESS_MAX) |_| {
            addTask("Task", false);
        }
        try expect(LEN == STRESS_MAX);
        end = std.time.milliTimestamp();
        std.debug.print("\n\tCreate: {d}ms\n", .{end - start});

        // Mark all tasks as complete
        start = std.time.milliTimestamp();
        for (1..LEN - 1) |i| {
            try completeTask(tasks[i].id);
        }
        end = std.time.milliTimestamp();
        std.debug.print("\tMark Complete: {d}ms\n", .{end - start});

        // Mark all tasks as incomplete
        start = std.time.milliTimestamp();
        for (1..LEN - 1) |i| {
            try incompleteTask(tasks[i].id);
        }
        end = std.time.milliTimestamp();
        std.debug.print("\tMark Incomplete: {d}ms\n", .{end - start});

        // Remove STRESS_MAX tasks
        start = std.time.milliTimestamp();
        for (0..LEN) |i| {
            _ = i;
            removeTask(0);
        }
        try expect(LEN == 0);
        end = std.time.milliTimestamp();
        std.debug.print("\tRemove: {d}ms\n", .{end - start});
    }
}

test "Starts with..." {
    const haystack: String = "Hello, World!";
    const needle: String = "Hello";
    try expect(startsWith(haystack, needle));
    try expect(!startsWith(haystack, "world"));
}

test "Parse string to number" {
    const s: []const u8 = "123";
    try expect(strToInt(s) == 123);
    const s2: []const u8 = "abc";
    try expect(strToInt(s2) == 0);
}
